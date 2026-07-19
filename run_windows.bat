@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "PROJECT_DIR=%~dp0"
set "GODOT_EXECUTABLE="

if defined GODOT_BIN (
    if exist "%GODOT_BIN%" set "GODOT_EXECUTABLE=%GODOT_BIN%"
    if not defined GODOT_EXECUTABLE (
        where "%GODOT_BIN%" >nul 2>nul && set "GODOT_EXECUTABLE=%GODOT_BIN%"
    )
    if not defined GODOT_EXECUTABLE (
        echo GODOT_BIN does not point to an executable: %GODOT_BIN% 1>&2
        exit /b 1
    )
)

if not defined GODOT_EXECUTABLE (
    where godot4.exe >nul 2>nul && set "GODOT_EXECUTABLE=godot4.exe"
)
if not defined GODOT_EXECUTABLE (
    where godot.exe >nul 2>nul && set "GODOT_EXECUTABLE=godot.exe"
)
if not defined GODOT_EXECUTABLE (
    for %%G in ("%PROJECT_DIR%Godot_v*-stable_win64.exe") do (
        if exist "%%~fG" if not defined GODOT_EXECUTABLE set "GODOT_EXECUTABLE=%%~fG"
    )
)
if not defined GODOT_EXECUTABLE (
    for %%G in ("%PROJECT_DIR%godot\Godot_v*-stable_win64.exe") do (
        if exist "%%~fG" if not defined GODOT_EXECUTABLE set "GODOT_EXECUTABLE=%%~fG"
    )
)

if not defined GODOT_EXECUTABLE (
    echo Godot 4 was not found. Double-click "Play Cowboy Trail.bat" to use the bundled engine, 1>&2
    echo or install Godot, add it to PATH, place its executable beside this script, or set GODOT_BIN. 1>&2
    exit /b 1
)

"%GODOT_EXECUTABLE%" --path "%PROJECT_DIR%" %*
exit /b %ERRORLEVEL%
