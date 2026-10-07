# Multigravity Duo Windows Uninstaller
$ErrorActionPreference = "Continue"

Write-Host "======================================================"
Write-Host " Uninstalling Multigravity Duo (Windows)"
Write-Host "======================================================"

$InstallDir = "$env:LOCALAPPDATA\Programs\Multigravity"

# 1. Remove binary and wrapper from AppData
if (Test-Path $InstallDir) {
    Write-Host "  → Removing Multigravity directory ($InstallDir)..."
    Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 2. Remove from user PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$InstallDir*") {
    Write-Host "  → Cleaning user PATH environment variable..."
    $parts = $userPath -split ';' | Where-Object { $_ -ne $InstallDir -and $_ -ne "$InstallDir\" -and $_ -ne "" }
    $newPath = $parts -join ';'
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
}

# 3. Clean up Start Menu shortcuts
$ProgramsFolder = [Environment]::GetFolderPath("Programs")
$ShortcutDir = "$ProgramsFolder\Multigravity"
if (Test-Path $ShortcutDir) {
    Write-Host "  → Removing Start Menu shortcuts ($ShortcutDir)..."
    Remove-Item -Path $ShortcutDir -Recurse -Force -ErrorAction SilentlyContinue
}

# 4. Check for profile data directory
$baseDir = if ($env:MULTIGRAVITY_HOME) { $env:MULTIGRAVITY_HOME } else { "$env:USERPROFILE\AntigravityProfiles" }
if (Test-Path $baseDir) {
    Write-Host ""
    Write-Host "Notice: Your profile data directory still exists at:"
    Write-Host "  $baseDir"
    Write-Host ""
    $resp = Read-Host "Do you want to permanently delete all profile data and accounts? [y/N]"
    if ($resp -match "^[yY]$") {
        Remove-Item -Path $baseDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  → Deleted profile data directory: $baseDir"
    } else {
        Write-Host "  → Kept profile data directory: $baseDir"
    }
}

Write-Host ""
Write-Host "✓ Multigravity Duo uninstalled successfully!"
