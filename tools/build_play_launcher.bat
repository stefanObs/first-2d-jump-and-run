@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0.."

rem Build Play Cowboy Trail.exe with the cowboy-head icon (csc from .NET Framework).

set "ROOT=%CD%"
set "SRC=%ROOT%\tools\play_cowboy_trail_launcher.cs"
set "OUT=%ROOT%\Play Cowboy Trail.exe"
set "ICON=%ROOT%\icon.ico"
set "CSC="

for %%V in (v4.0.30319 v3.5) do (
	if exist "%WINDIR%\Microsoft.NET\Framework64\%%V\csc.exe" if not defined CSC set "CSC=%WINDIR%\Microsoft.NET\Framework64\%%V\csc.exe"
	if exist "%WINDIR%\Microsoft.NET\Framework\%%V\csc.exe" if not defined CSC set "CSC=%WINDIR%\Microsoft.NET\Framework\%%V\csc.exe"
)

if not defined CSC (
	where csc.exe >nul 2>nul && for /f "delims=" %%C in ('where csc.exe') do if not defined CSC set "CSC=%%C"
)

if not defined CSC (
	echo Could not find the C# compiler ^(csc.exe^).
	echo Install .NET Framework Developer Pack, or use Play Cowboy Trail.bat as a fallback.
	exit /b 1
)

if not exist "%SRC%" (
	echo Missing %SRC%
	exit /b 1
)
if not exist "%ICON%" (
	echo Missing %ICON%
	exit /b 1
)

echo Building Play Cowboy Trail.exe ...
"%CSC%" /nologo /target:winexe /optimize+ /reference:System.Windows.Forms.dll /reference:System.IO.Compression.FileSystem.dll /win32icon:"%ICON%" /out:"%OUT%" "%SRC%"
if errorlevel 1 (
	echo Compile failed.
	exit /b 1
)

echo Built: %OUT%
exit /b 0
