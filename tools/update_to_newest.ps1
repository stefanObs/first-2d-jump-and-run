#Requires -Version 5.0
<#
.SYNOPSIS
  Download the newest Cowboy Trail files from GitHub into this project folder.
  Uses only built-in PowerShell (Invoke-WebRequest + Expand-Archive). No git/Python.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot
)

$ErrorActionPreference = "Stop"

$RepoOwner = "stefanObs"
$RepoName = "first-2d-jump-and-run"
$Branch = "main"
$ZipUrl = "https://github.com/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
$UserAgent = "CowboyTrail-Updater/1.0"

function Test-IsPreserved {
    param([string]$RelativePath)
    $rel = ($RelativePath -replace "\\", "/").TrimStart("./")
    if ([string]::IsNullOrWhiteSpace($rel)) { return $true }

    $top = ($rel -split "/")[0]
    $preserveTops = @("savegames", ".git", ".godot")
    if ($preserveTops -contains $top) { return $true }

    $prefixes = @(
        "savegames/",
        ".git/",
        "godot/macos/",
        "dist/"
    )
    foreach ($prefix in $prefixes) {
        if ($rel -eq $prefix.TrimEnd("/") -or $rel.StartsWith($prefix)) {
            return $true
        }
    }

    if ($rel.StartsWith("godot/") -and $rel.ToLower().EndsWith(".exe")) {
        return $true
    }
    if ($rel -eq "Play Cowboy Trail.exe") {
        return $true
    }
    return $false
}

function Get-ContentVersion {
    param([string]$Root)
    $stamp = Join-Path $Root "content_version.txt"
    if (Test-Path -LiteralPath $stamp) {
        return ((Get-Content -LiteralPath $stamp -Raw).Trim())
    }
    return "(unknown)"
}

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$projectFile = Join-Path $ProjectRoot "project.godot"
if (-not (Test-Path -LiteralPath $projectFile)) {
    Write-Error "No project.godot in $ProjectRoot. Keep the updater inside the game folder."
}

$before = Get-ContentVersion -Root $ProjectRoot
Write-Host "Current content version: $before"
Write-Host "Game folder: $ProjectRoot"

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cowboy_trail_update_" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempRoot | Out-Null

try {
    $zipPath = Join-Path $tempRoot "cowboy-trail-main.zip"
    Write-Host "Downloading newest version from GitHub ($Branch)..."
    Write-Host "  $ZipUrl"

    # Prefer TLS 1.2+ on older Windows PowerShell hosts.
    try {
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.SecurityProtocolType]::Tls12 -bor `
            [Net.SecurityProtocolType]::Tls11 -bor `
            [Net.SecurityProtocolType]::Tls
    } catch {}

    $headers = @{ "User-Agent" = $UserAgent }
    Invoke-WebRequest -Uri $ZipUrl -OutFile $zipPath -Headers $headers -UseBasicParsing

    Write-Host "Download finished."
    Write-Host "Unpacking update..."

    $extractDir = Join-Path $tempRoot "extracted"
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

    $packageRoot = Get-ChildItem -LiteralPath $extractDir -Directory | Select-Object -First 1
    if ($null -eq $packageRoot) {
        throw "Unexpected zip layout (no folder inside archive)."
    }
    $packagePath = $packageRoot.FullName
    if (-not (Test-Path -LiteralPath (Join-Path $packagePath "project.godot"))) {
        throw "Update package is missing project.godot."
    }

    $after = Get-ContentVersion -Root $packagePath
    Write-Host "Newest content version: $after"

    $sourceFiles = @{}
    Get-ChildItem -LiteralPath $packagePath -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($packagePath.Length).TrimStart("\", "/")
        $relUnix = $rel -replace "\\", "/"
        if (-not (Test-IsPreserved -RelativePath $relUnix)) {
            $sourceFiles[$relUnix] = $_.FullName
        }
    }

    $removed = 0
    Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
        ForEach-Object {
            $rel = $_.FullName.Substring($ProjectRoot.Length).TrimStart("\", "/")
            $relUnix = $rel -replace "\\", "/"
            if (Test-IsPreserved -RelativePath $relUnix) { return }
            if (-not $sourceFiles.ContainsKey($relUnix)) {
                Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue
                $removed++
            }
        }

    $copied = 0
    foreach ($relUnix in ($sourceFiles.Keys | Sort-Object)) {
        $src = $sourceFiles[$relUnix]
        $dest = Join-Path $ProjectRoot ($relUnix -replace "/", [IO.Path]::DirectorySeparatorChar)
        $destDir = Split-Path -Parent $dest
        if (-not (Test-Path -LiteralPath $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $src -Destination $dest -Force
        $copied++
    }

    $godotCache = Join-Path $ProjectRoot ".godot"
    if (Test-Path -LiteralPath $godotCache) {
        Write-Host "Clearing local Godot import cache so the next launch refreshes assets..."
        Remove-Item -LiteralPath $godotCache -Recurse -Force -ErrorAction SilentlyContinue
    }

    Write-Host ""
    Write-Host "Updated $copied files ($removed obsolete local files removed)."
    Write-Host "Content version: $before -> $after"
    Write-Host "Savegames and cached Godot engines were kept."
    Write-Host "Start the game with Play Cowboy Trail; it will reimport assets."
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
