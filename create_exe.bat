@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem Build a portable Windows .exe (no install required).
rem Output: dist\windows\CowboyTrail.exe
rem Saves appear in savegames\ next to the exe at runtime.

cd /d "%~dp0"
set "PROJECT_DIR=%CD%"
set "DIST_DIR=%PROJECT_DIR%\dist\windows"
set "EXE_NAME=CowboyTrail.exe"
set "EXPORT_PRESET=Windows Desktop"
set "GODOT_VERSION=4.4.1.stable"
set "TEMPLATE_VERSION=4.4.1-stable"
set "TEMPLATE_URL=https://github.com/godotengine/godot/releases/download/%TEMPLATE_VERSION%/Godot_v%TEMPLATE_VERSION%_export_templates.tpz"
set "TEMPLATES_DIR=%APPDATA%\Godot\export_templates\%GODOT_VERSION%"
set "GODOT_EXECUTABLE="
set "LOG=%PROJECT_DIR%\dist\create_exe_log.txt"

if not exist "%PROJECT_DIR%\dist" mkdir "%PROJECT_DIR%\dist"
echo Cowboy Trail create_exe log > "%LOG%"
echo. >> "%LOG%"

call :log "Project: %PROJECT_DIR%"

rem Also keep the cowboy-icon play launcher up to date.
if exist "%PROJECT_DIR%\tools\build_play_launcher.bat" (
	call "%PROJECT_DIR%\tools\build_play_launcher.bat" >> "%LOG%" 2>&1
)

if defined GODOT_BIN (
	if exist "%GODOT_BIN%" set "GODOT_EXECUTABLE=%GODOT_BIN%"
)

if not defined GODOT_EXECUTABLE (
	if exist "%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe" set "GODOT_EXECUTABLE=%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe"
)
if not defined GODOT_EXECUTABLE (
	if exist "%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe.zip" (
		call :log "Unpacking bundled Godot editor..."
		powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe.zip' -DestinationPath '%PROJECT_DIR%\godot' -Force"
	)
	if exist "%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe" set "GODOT_EXECUTABLE=%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe"
)
if not defined GODOT_EXECUTABLE (
	where godot.exe >nul 2>nul && for /f "delims=" %%G in ('where godot.exe') do if not defined GODOT_EXECUTABLE set "GODOT_EXECUTABLE=%%G"
)

if not defined GODOT_EXECUTABLE (
	call :fail "Godot 4 editor was not found. Keep godot\Godot_v4.4.1-stable_win64.exe.zip in the project, or set GODOT_BIN."
)

call :log "Using Godot: %GODOT_EXECUTABLE%"

if not exist "%TEMPLATES_DIR%\windows_release_x86_64.exe" (
	call :log "Downloading export templates for %GODOT_VERSION% ..."
	if not exist "%TEMPLATES_DIR%" mkdir "%TEMPLATES_DIR%"
	set "TMPDIR=%TEMP%\cowboy_trail_templates_%RANDOM%"
	mkdir "!TMPDIR!"
	powershell -NoProfile -ExecutionPolicy Bypass -Command ^
		"$ErrorActionPreference='Stop'; $ProgressPreference='SilentlyContinue'; $zip='!TMPDIR!\templates.zip'; $url='%TEMPLATE_URL%'; try { Invoke-WebRequest -Uri $url -OutFile $zip } catch { Write-Error $_; exit 1 }; if (-not (Test-Path $zip)) { throw 'Download produced no file' }; Expand-Archive -LiteralPath $zip -DestinationPath '!TMPDIR!\extracted' -Force; if (-not (Test-Path '!TMPDIR!\extracted\templates')) { throw 'Template archive missing templates/ folder' }; Copy-Item -Path '!TMPDIR!\extracted\templates\*' -Destination '%TEMPLATES_DIR%' -Recurse -Force" >> "%LOG%" 2>&1
	if errorlevel 1 (
		call :fail "Could not download/extract export templates. See dist\create_exe_log.txt"
	)
	if not exist "%TEMPLATES_DIR%\windows_release_x86_64.exe" (
		call :fail "Templates installed but windows_release_x86_64.exe is missing in:%TEMPLATES_DIR%"
	)
	echo %GODOT_VERSION%> "%TEMPLATES_DIR%\version.txt"
	rmdir /s /q "!TMPDIR!" 2>nul
)

call :log "Importing project assets before export..."
"%GODOT_EXECUTABLE%" --headless --path "%PROJECT_DIR%" --import >> "%LOG%" 2>&1
if errorlevel 1 (
	call :fail "Godot import failed. See dist\create_exe_log.txt"
)

if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

set "EXPORT_PATH=%DIST_DIR%\%EXE_NAME%"
set "EXPORT_PATH_POSIX=%EXPORT_PATH:\=/%"

> "%PROJECT_DIR%\export_presets.cfg" (
	echo [preset.0]
	echo.
	echo name="%EXPORT_PRESET%"
	echo platform="Windows Desktop"
	echo runnable=true
	echo advanced_options=false
	echo dedicated_server=false
	echo custom_features=""
	echo export_filter="all_resources"
	echo include_filter=""
	echo exclude_filter="savegames/*, dist/*, godot/*, *.bat, *.sh, tests/*, .git/*, tools/*"
	echo export_path="%EXPORT_PATH_POSIX%"
	echo encryption_include_filters=""
	echo encryption_exclude_filters=""
	echo encrypt_pck=false
	echo encrypt_directory=false
	echo script_export_mode=2
	echo.
	echo [preset.0.options]
	echo.
	echo custom_template/debug=""
	echo custom_template/release=""
	echo debug/export_console_wrapper=0
	echo binary_format/embed_pck=true
	echo texture_format/s3tc_bptc=true
	echo texture_format/etc2_astc=false
	echo binary_format/architecture="x86_64"
	echo codesign/enable=false
	echo application/modify_resources=true
	echo application/icon="res://icon.ico"
	echo application/console_wrapper_icon="res://icon.ico"
	echo application/icon_interpolation=0
	echo application/file_version="1.3.6.0"
	echo application/product_version="1.3.6.0"
	echo application/company_name="Cowboy Trail"
	echo application/product_name="Cowboy Trail"
	echo application/file_description="A friendly cowboy jump-and-run for kids"
	echo application/copyright=""
	echo application/trademarks=""
	echo application/export_angle=0
	echo application/export_d3d12=0
	echo application/d3d12_agility_sdk_multiarch=true
	echo ssh_remote_deploy/enabled=false
)

> "%DIST_DIR%\README.txt" (
	echo Cowboy Trail — portable Windows build
	echo =====================================
	echo.
	echo Double-click CowboyTrail.exe to play. No installation required.
	echo.
	echo Your progress is stored in a "savegames" folder next to this exe.
	echo Copy the whole folder ^(exe + savegames^) to keep progress when moving PCs.
)

call :log "Exporting %EXE_NAME% ..."
"%GODOT_EXECUTABLE%" --headless --path "%PROJECT_DIR%" --export-release "%EXPORT_PRESET%" "%EXPORT_PATH%" >> "%LOG%" 2>&1
set "EXPORT_ERR=!ERRORLEVEL!"
if not "!EXPORT_ERR!"=="0" (
	call :fail "Godot export failed with exit !EXPORT_ERR!. See dist\create_exe_log.txt"
)
if not exist "%EXPORT_PATH%" (
	call :fail "Export finished but %EXPORT_PATH% was not created. See dist\create_exe_log.txt"
)

if exist "%PROJECT_DIR%\icon.ico" copy /Y "%PROJECT_DIR%\icon.ico" "%DIST_DIR%\icon.ico" >nul

call :log "Done: %EXPORT_PATH%"
echo.
echo Done.
echo Portable build: %EXPORT_PATH%
echo Log: %LOG%
echo Saves will appear beside the exe in: savegames\
exit /b 0

:log
echo %~1
echo %~1 >> "%LOG%"
exit /b 0

:fail
echo.
echo ERROR: %~1
echo %~1 >> "%LOG%"
echo.
echo Full log: %LOG%
echo.
pause
exit /b 1
