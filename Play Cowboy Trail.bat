@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "ENGINE=%ROOT%\godot\Godot_v4.4.1-stable_win64.exe"
set "ENGINE_ZIP=%ROOT%\godot\Godot_v4.4.1-stable_win64.exe.zip"
set "STAMP_FILE=%ROOT%\content_version.txt"
set "CACHE_STAMP=%ROOT%\.godot\cowboy_trail_content_version.txt"
set "LAUNCHER=%ROOT%\Play Cowboy Trail.exe"

rem --- This launcher runs the game from the project files beside it, so it must
rem --- stay inside the Cowboy Trail folder. Explain clearly if it was copied out. ---
if not exist "%ROOT%\project.godot" (
	echo.
	echo The Cowboy Trail game files were not found next to this launcher.
	echo Keep "Play Cowboy Trail.bat" inside the Cowboy Trail folder.
	echo.
	echo To play from anywhere, build the portable game with create_exe.bat
	echo and copy CowboyTrail.exe instead.
	echo.
	pause
	exit /b 1
)

rem --- Prefer the cowboy-icon .exe launcher (.bat files cannot show custom icons) ---
if not exist "%LAUNCHER%" (
	if exist "%ROOT%\tools\build_play_launcher.bat" (
		echo Building Play Cowboy Trail.exe with the game icon...
		call "%ROOT%\tools\build_play_launcher.bat"
	)
)
if exist "%LAUNCHER%" (
	start "" "%LAUNCHER%"
	exit /b 0
)

rem --- Fallback if the C# launcher could not be built ---
echo.
echo Note: Could not build Play Cowboy Trail.exe ^(cowboy icon^).
echo Continuing with the classic launcher. Install .NET Framework to get the icon.
echo.

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
	echo.
	if exist "%ROOT%\.godot" rmdir /s /q "%ROOT%\.godot" 2>nul
	"%ENGINE%" --headless --path "%ROOT%" --import
	if errorlevel 1 (
		echo Could not import the game.
		pause
		exit /b 1
	)
	if not exist "%ROOT%\.godot" mkdir "%ROOT%\.godot"
	copy /Y "%STAMP_FILE%" "%CACHE_STAMP%" >nul
)

start "" "%ENGINE%" --path "%ROOT%"
endlocal
