@echo off
echo.
echo ============================================================
echo   Dext - Build and Test Suite
echo ============================================================
echo.

call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"

echo.
echo [1/3] Building Dext.EF.Core...
msbuild "C:\dev\Dext\DextRepository\Sources\Dext.EF.Core.dproj" /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed for Dext.EF.Core
    exit /b %errorlevel%
)

echo.
echo [2/3] Building Dext.EntityDataSet.Tests...
msbuild "C:\dev\Dext\DextRepository\Sources\Tests\Dext.EntityDataSet.Tests.dproj" /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal /nologo
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed for Dext.EntityDataSet.Tests
    exit /b %errorlevel%
)

echo.
echo [3/3] Running Tests...
"C:\dev\Dext\DextRepository\Output\Dext.EntityDataSet.Tests.exe"

set EXIT_CODE=%errorlevel%
if %EXIT_CODE% neq 0 (
    echo.
    echo WARNING: Some tests failed (Exit Code: %EXIT_CODE%)
) else (
    echo.
    echo SUCCESS: All tests passed!
)

exit /b %EXIT_CODE%
