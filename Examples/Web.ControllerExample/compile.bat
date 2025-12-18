@echo off
setlocal

echo Setting up Delphi environment...
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"

echo.
echo ==========================================
echo Building Web.ControllerExample
echo ==========================================
echo.

set BUILD_CONFIG=Debug
set PLATFORM=Win32
set FRAMEWORK_OUTPUT=%~dp0..\..\Output
set OUTPUT_PATH=%~dp0Output

if not exist "%OUTPUT_PATH%" mkdir "%OUTPUT_PATH%"

echo Building Web.ControllerExample.exe...
msbuild "Web.ControllerExample.dproj" /t:Build /p:Configuration=%BUILD_CONFIG% /p:Platform=%PLATFORM% /p:DCC_ExeOutput="%OUTPUT_PATH%" /p:DCC_DcuOutput="%OUTPUT_PATH%" /p:DCC_UnitSearchPath="%FRAMEWORK_OUTPUT%" /v:minimal

if %ERRORLEVEL% NEQ 0 goto Error

echo.
echo ==========================================
echo Build Completed Successfully!
echo Output: %OUTPUT_PATH%\Web.ControllerExample.exe
echo ==========================================
if not "%1"=="--no-wait" pause
exit /b 0

:Error
echo.
echo ==========================================
echo BUILD FAILED!
echo ==========================================
if not "%1"=="--no-wait" pause
exit /b 1
