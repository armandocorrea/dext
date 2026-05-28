# run_web_tests.ps1
# Set up environment and compile/run only the Web Unit Tests project.

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$DextRoot = Split-Path -Parent $PSScriptRoot

# Load environment
$env:DEXT_PROJECT_TYPE = "Tests"
. "$PSScriptRoot\Scripts\set_env.ps1" Win32 Debug

$TestsOutput = Join-Path $DextRoot "Tests\Output"
$projPath = Join-Path $DextRoot "Tests\Web\Dext.Web.UnitTests.dproj"

$msbuildArgs = @(
    "`"$projPath`"",
    "/t:Build",
    "/p:Configuration=$($env:BUILD_CONFIG)",
    "/p:Platform=$($env:PLATFORM)",
    "/p:DCC_ExeOutput=`"$TestsOutput`"",
    "/p:DCC_DcuOutput=`"$env:OUTPUT_PATH`"",
    "/p:DCC_UnitSearchPath=`"$($env:SEARCH_PATH)`"",
    "/p:DCC_BuildAllUnits=true",
    "/v:minimal",
    "/nologo"
)

Write-Host "Building Dext.Web.UnitTests..." -ForegroundColor Cyan
$process = Start-Process -FilePath "msbuild" -ArgumentList $msbuildArgs -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0) {
    Write-Host "Build succeeded! Running Dext.Web.UnitTests..." -ForegroundColor Green
    $exePath = Join-Path $TestsOutput "Dext.Web.UnitTests.exe"
    if (Test-Path $exePath) {
        # Execute the test executable
        & $exePath -no-wait
    } else {
        Write-Error "Executable not found at: $exePath"
        exit 1
    }
} else {
    Write-Error "Build failed with exit code $($process.ExitCode)"
    exit 1
}
