# Downloads the pinned PDFium build used for PDF previews and places
# pdfium.dll next to AceUtils.exe (the project root).
#   powershell -ExecutionPolicy Bypass -File tools\fetch-pdfium.ps1
#
# Source: https://github.com/bblanchon/pdfium-binaries (PDFium is BSD-3-Clause;
# the binary package is MIT). License texts: third_party\pdfium\.
# AceUtils is built as 32-bit (i386-win32), so the x86 package is used.

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

$Release = 'chromium/8125'
$Asset = 'pdfium-win-x86.tgz'
$Sha256 = '5AA1EB3E7DE0589534245A181CB51DEF90D1DC76E987AEA4BE524A8CB3DB1069'
$Url = "https://github.com/bblanchon/pdfium-binaries/releases/download/$Release/$Asset"

$Work = Join-Path ([IO.Path]::GetTempPath()) ("ace-pdfium-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $Work | Out-Null
try {
    $Archive = Join-Path $Work $Asset
    Write-Host "Downloading $Url"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $Url -OutFile $Archive -UseBasicParsing

    $Actual = (Get-FileHash -Algorithm SHA256 $Archive).Hash
    if ($Actual -ne $Sha256) { throw "Checksum mismatch for $Asset (expected $Sha256, got $Actual)" }

    tar -xzf $Archive -C $Work bin/pdfium.dll
    if ($LASTEXITCODE -ne 0) { throw 'Failed to extract pdfium.dll' }
    Copy-Item -Force (Join-Path $Work 'bin\pdfium.dll') (Join-Path $Root 'pdfium.dll')
    Write-Host "Installed $(Join-Path $Root 'pdfium.dll')"
}
finally {
    Remove-Item -Recurse -Force $Work -ErrorAction SilentlyContinue
}
