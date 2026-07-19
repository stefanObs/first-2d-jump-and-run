@echo off
setlocal enableextensions
cd /d "%~dp0"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"
set "ENGINE=%ROOT%\godot\Godot_v4.4.1-stable_win64.exe"
set "ENGINE_ZIP=%ROOT%\godot\Godot_v4.4.1-stable_win64.exe.zip"

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

rem --- First launch only: import the game assets ---
if not exist "%ROOT%\.godot" (
	echo Getting Cowboy Trail ready for the first time, please wait...
	"%ENGINE%" --headless --path "%ROOT%" --import
)

rem --- Start the game ---
start "" "%ENGINE%" --path "%ROOT%"
endlocal
