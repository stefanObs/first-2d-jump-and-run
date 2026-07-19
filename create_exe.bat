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
set "TEMPLATE_URL=https://github.com/godotengine/godot-builds/releases/download/%TEMPLATE_VERSION%/Godot_v%TEMPLATE_VERSION%_export_templates.tpz"
set "TEMPLATES_DIR=%APPDATA%\Godot\export_templates\%GODOT_VERSION%"
set "GODOT_EXECUTABLE="

if defined GODOT_BIN (
	if exist "%GODOT_BIN%" set "GODOT_EXECUTABLE=%GODOT_BIN%"
	if not defined GODOT_EXECUTABLE (
		where "%GODOT_BIN%" >nul 2>nul && set "GODOT_EXECUTABLE=%GODOT_BIN%"
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
	if exist "%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe.zip" (
		echo Unpacking bundled Godot editor for export...
		powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '%PROJECT_DIR%\godot\Godot_v4.4.1-stable_win64.exe.zip' -DestinationPath '%PROJECT_DIR%\godot' -Force"
	)
	for %%G in ("%PROJECT_DIR%\godot\Godot_v*-stable_win64.exe") do (
		if exist "%%~fG" if not defined GODOT_EXECUTABLE set "GODOT_EXECUTABLE=%%~fG"
	)
)

if not defined GODOT_EXECUTABLE (
	echo Godot 4 was not found. Install it, add it to PATH, place it in godot\, or set GODOT_BIN.
	exit /b 1
)

	if not exist "%TEMPLATES_DIR%\windows_release_x86_64.exe" (
	echo Downloading Godot %GODOT_VERSION% Windows export templates...
	if not exist "%TEMPLATES_DIR%" mkdir "%TEMPLATES_DIR%"
	set "TMPDIR=%TEMP%\cowboy_trail_templates"
	if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%"
	mkdir "%TMPDIR%"
	powershell -NoProfile -ExecutionPolicy Bypass -Command ^
		"$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri '%TEMPLATE_URL%' -OutFile '%TMPDIR%\templates.zip'; Expand-Archive -LiteralPath '%TMPDIR%\templates.zip' -DestinationPath '%TMPDIR%\extracted' -Force; Copy-Item -Path '%TMPDIR%\extracted\templates\*' -Destination '%TEMPLATES_DIR%' -Recurse -Force"
	if not exist "%TEMPLATES_DIR%\windows_release_x86_64.exe" (
		echo Failed to install Windows export templates into:
		echo   %TEMPLATES_DIR%
		exit /b 1
	)
	echo %GODOT_VERSION%> "%TEMPLATES_DIR%\version.txt"
)

if not exist "%DIST_DIR%" mkdir "%DIST_DIR%"

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
	echo exclude_filter="savegames/*, dist/*, godot/*, *.bat, *.sh, tests/*, .git/*"
	echo export_path="%DIST_DIR:\=/%/%EXE_NAME%"
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
	echo application/file_version="1.3.5.0"
	echo application/product_version="1.3.5.0"
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

echo Exporting %EXE_NAME% ...
"%GODOT_EXECUTABLE%" --headless --path "%PROJECT_DIR%" --export-release "%EXPORT_PRESET%" "%DIST_DIR%\%EXE_NAME%"
if errorlevel 1 (
	echo Export failed.
	exit /b 1
)
if not exist "%DIST_DIR%\%EXE_NAME%" (
	echo Export failed: %DIST_DIR%\%EXE_NAME% not found.
	exit /b 1
)

if exist "%PROJECT_DIR%\icon.ico" copy /Y "%PROJECT_DIR%\icon.ico" "%DIST_DIR%\icon.ico" >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
	"$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%DIST_DIR%\Cowboy Trail.lnk'); $s.TargetPath = '%DIST_DIR%\%EXE_NAME%'; $s.WorkingDirectory = '%DIST_DIR%'; $s.IconLocation = '%DIST_DIR%\icon.ico'; $s.Description = 'Cowboy Trail'; $s.Save()"

echo.
echo Done.
echo Portable build: %DIST_DIR%\%EXE_NAME%
echo Saves will appear beside the exe in: savegames\
exit /b 0
