@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

if not exist "%ROOT%\project.godot" (
	echo.
	echo Keep update_to_newest.bat inside the Cowboy Trail game folder.
	echo.
	pause
	exit /b 1
)

echo.
echo Updating Cowboy Trail to the newest version from GitHub...
echo This keeps your savegames and the cached game engine.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\update_to_newest.ps1" -ProjectRoot "%ROOT%"
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" (
	echo.
	echo Update failed.
	pause
	exit /b %ERR%
)

echo.
pause
endlocal
