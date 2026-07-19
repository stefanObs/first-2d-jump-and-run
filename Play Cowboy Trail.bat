@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "ENGINE=%ROOT%\godot\Godot_v4.4.1-stable_win64.exe"
set "ENGINE_ZIP=%ROOT%\godot\Godot_v4.4.1-stable_win64.exe.zip"
set "STAMP_FILE=%ROOT%\content_version.txt"
set "CACHE_STAMP=%ROOT%\.godot\cowboy_trail_content_version.txt"
set "ICON=%ROOT%\icon.ico"
set "SHORTCUT=%ROOT%\Play Cowboy Trail.lnk"

rem --- First launch: unpack the bundled Godot engine (no install needed) ---
if not exist "%ENGINE%" (
	echo Unpacking the game engine, one moment...
	powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%ENGINE_ZIP%' -DestinationPath '%ROOT%\godot' -Force"
)
if not exist "%ENGINE%" (
	echo.
	echo Could not unpack the engine. Please keep the "godot" folder next to this file.
	echo.
	pause
	exit /b 1
)

rem --- Shortcut with cowboy-head icon for Explorer / taskbar pinning ---
if exist "%ICON%" (
	powershell -NoProfile -ExecutionPolicy Bypass -Command ^
		"$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%SHORTCUT%'); $s.TargetPath = '%ROOT%\Play Cowboy Trail.bat'; $s.WorkingDirectory = '%ROOT%'; $s.IconLocation = '%ICON%'; $s.Description = 'Cowboy Trail'; $s.Save()"
)

rem --- Refresh assets whenever the repo content version changes (git pull / new checkout) ---
set "NEED_IMPORT=0"
if not exist "%ROOT%\.godot" set "NEED_IMPORT=1"
if not exist "%STAMP_FILE%" set "NEED_IMPORT=1"
if not exist "%CACHE_STAMP%" set "NEED_IMPORT=1"
if "%NEED_IMPORT%"=="0" (
	fc /b "%STAMP_FILE%" "%CACHE_STAMP%" >nul 2>nul
	if errorlevel 1 set "NEED_IMPORT=1"
)

if "%NEED_IMPORT%"=="1" (
	echo.
	echo Updating Cowboy Trail to the latest checked-out version...
	echo This can take a minute the first time or after a git pull.
	echo.
	if exist "%ROOT%\.godot" (
		rmdir /s /q "%ROOT%\.godot" 2>nul
	)
	"%ENGINE%" --headless --path "%ROOT%" --import
	if errorlevel 1 (
		echo.
		echo Could not import the game. Check that the project files are complete.
		echo.
		pause
		exit /b 1
	)
	if not exist "%ROOT%\.godot" mkdir "%ROOT%\.godot"
	copy /Y "%STAMP_FILE%" "%CACHE_STAMP%" >nul
)

rem --- Start the game ---
start "" "%ENGINE%" --path "%ROOT%"
endlocal
