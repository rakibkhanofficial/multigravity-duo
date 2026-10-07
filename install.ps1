# Multigravity Duo Windows Installer
$ErrorActionPreference = "Stop"

$REPO = "rakibkhanofficial/multigravity-duo"
$BRANCH = "main"
$RAW = "https://raw.githubusercontent.com/$REPO/$BRANCH"

$InstallDir = "$env:LOCALAPPDATA\Programs\Multigravity"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

Write-Host "Installing Multigravity Duo to $InstallDir..."

Invoke-WebRequest -Uri "$RAW/multigravity.ps1" -OutFile "$InstallDir\multigravity.ps1"
Invoke-WebRequest -Uri "$RAW/icon.ico" -OutFile "$InstallDir\icon.ico" -ErrorAction SilentlyContinue

# Create a multigravity.cmd wrapper in the folder so it runs easily in cmd/powershell
$cmdContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$InstallDir\multigravity.ps1" %*
"@
Set-Content -Path "$InstallDir\multigravity.cmd" -Value $cmdContent

# Add to user PATH if not present
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    Write-Host "Added $InstallDir to user PATH."
}

Write-Host ""
Write-Host "✓ Multigravity Duo installed successfully!"
Write-Host ""
Write-Host "Run 'multigravity doctor' to verify your installation."
