@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "GODOT_EXECUTABLE="
set "STAMP_FILE=%PROJECT_DIR%\content_version.txt"
set "CACHE_STAMP=%PROJECT_DIR%\.godot\cowboy_trail_content_version.txt"

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
    for %%G in ("%PROJECT_DIR%\Godot_v*-stable_win64.exe") do (
        if exist "%%~fG" if not defined GODOT_EXECUTABLE set "GODOT_EXECUTABLE=%%~fG"
    )
)
if not defined GODOT_EXECUTABLE (
    for %%G in ("%PROJECT_DIR%\godot\Godot_v*-stable_win64.exe") do (
        if exist "%%~fG" if not defined GODOT_EXECUTABLE set "GODOT_EXECUTABLE=%%~fG"
    )
)

if not defined GODOT_EXECUTABLE (
    echo Godot 4 was not found. Double-click "Play Cowboy Trail.bat" to use the bundled engine, 1>&2
    echo or install Godot, add it to PATH, place its executable beside this script, or set GODOT_BIN. 1>&2
    exit /b 1
)

set "NEED_IMPORT=0"
if not exist "%PROJECT_DIR%\.godot" set "NEED_IMPORT=1"
if not exist "%STAMP_FILE%" set "NEED_IMPORT=1"
if not exist "%CACHE_STAMP%" set "NEED_IMPORT=1"
if "%NEED_IMPORT%"=="0" (
    fc /b "%STAMP_FILE%" "%CACHE_STAMP%" >nul 2>nul
    if errorlevel 1 set "NEED_IMPORT=1"
)
if "%NEED_IMPORT%"=="1" (
    echo Updating Cowboy Trail to the latest checked-out version...
    if exist "%PROJECT_DIR%\.godot" rmdir /s /q "%PROJECT_DIR%\.godot" 2>nul
    "%GODOT_EXECUTABLE%" --headless --path "%PROJECT_DIR%" --import
    if not exist "%PROJECT_DIR%\.godot" mkdir "%PROJECT_DIR%\.godot"
    copy /Y "%STAMP_FILE%" "%CACHE_STAMP%" >nul
)

"%GODOT_EXECUTABLE%" --path "%PROJECT_DIR%" %*
exit /b %ERRORLEVEL%
