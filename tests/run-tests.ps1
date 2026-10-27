# Builds and runs the Ace's Utilities unit tests.
#   powershell -ExecutionPolicy Bypass -File tests\run-tests.ps1
# Exit code is non-zero if the build fails or any test fails/errors.

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Lazbuild = if ($env:LAZBUILD) { $env:LAZBUILD } elseif (Test-Path 'C:\lazarus\lazbuild.exe') { 'C:\lazarus\lazbuild.exe' } else { 'lazbuild' }

# Stale root unit files shadow freshly compiled ones (see AGENTS.md section 5)
Remove-Item -Force (Join-Path $Root '*.ppu'), (Join-Path $Root '*.o') -ErrorAction SilentlyContinue

& $Lazbuild -B (Join-Path $PSScriptRoot 'AceTests.lpi')
if ($LASTEXITCODE -ne 0) { Write-Error 'Test build failed.'; exit 1 }

$BinDir = Join-Path $PSScriptRoot 'bin'
$Dll = Join-Path $Root 'pdfium.dll'
if (-not (Test-Path $Dll)) {
    & (Join-Path $Root 'tools\fetch-pdfium.ps1')
}
Copy-Item -Force $Dll $BinDir

$Exe = Join-Path $BinDir 'AceTests.exe'
$Output = & $Exe --all --format=plain 2>&1
$Output | ForEach-Object { Write-Host $_ }
$Code = $LASTEXITCODE

$Summary = $Output | Select-String -Pattern 'Number of (errors|failures):\s*(\d+)'
$Bad = ($Summary | ForEach-Object { [int]$_.Matches[0].Groups[2].Value } | Measure-Object -Sum).Sum
if ($Code -ne 0 -or $Bad -gt 0 -or -not $Summary) { Write-Host "TESTS FAILED" -ForegroundColor Red; exit 1 }
Write-Host "ALL TESTS PASSED" -ForegroundColor Green
exit 0
