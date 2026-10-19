# Builds dist\<name>-<version>-windows-x64.zip, and the -setup.exe installer
# if Inno Setup 6 is installed (or $env:ISCC points to ISCC.exe). <name> is the
# package name in Cargo.toml.
# Pass -Installer to fail if Inno Setup is missing, as the release workflow does.
param([switch]$Installer)

Set-Location (Split-Path $PSScriptRoot -Parent)

# Read the app identity from Cargo.toml. Cargo writes UTF-8.
$encoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
try { $metadata = cargo metadata --locked --no-deps --format-version 1 }
finally { [Console]::OutputEncoding = $encoding }
if ($LASTEXITCODE -ne 0) { throw 'cargo metadata failed' }
$package = ($metadata -join "`n" | ConvertFrom-Json).packages[0]
$name = $package.name
$version = $package.version
$appName = $package.description
$appId = $package.metadata.app.identifier
if (-not $appName -or $appName -match '[\x00-\x1f\x7f\\/:*?"<>|{},]') {
    throw 'In Cargo.toml, set package.description to the app name. Do not use control characters or \ / : * ? " < > | { } ,'
}
if ($appId -isnot [string] -or $appId.Length -gt 127 -or $appId -notmatch '\A[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+\z') {
    throw 'In Cargo.toml, set package.metadata.app.identifier to a reverse-domain ID, for example com.example.my-app. Use only letters, digits, hyphens and periods, and 127 characters or fewer.'
}

cargo build --release --locked
if ($LASTEXITCODE -ne 0) { throw 'cargo build failed' }
# After cargo: Windows PowerShell treats cargo's progress output as errors.
$ErrorActionPreference = 'Stop'

New-Item -ItemType Directory -Path dist -Force | Out-Null
Compress-Archive -Path "target\release\$name.exe" -DestinationPath "dist\$name-$version-windows-x64.zip" -Force

$iscc = @($env:ISCC, "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe", "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe") |
    Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if ($iscc) {
    & $iscc /Q "/DAppName=$appName" "/DAppPackage=$name" "/DAppId=$appId" "/DAppVersion=$version" installer\app.iss
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed' }
} else {
    if ($Installer) { throw 'Inno Setup 6 is required to build the installer.' }
    Write-Warning 'Inno Setup 6 not found; skipped the installer.'
}
Get-ChildItem dist
