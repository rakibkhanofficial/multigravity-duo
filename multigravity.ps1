<#
.SYNOPSIS
Multigravity Duo — Run multiple Antigravity IDE and Antigravity Companion profiles at the same time.
#>

param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$cmd,
    
    [Parameter(Position = 1, Mandatory = $false)]
    [string]$arg1,

    [Parameter(Position = 2, Mandatory = $false)]
    [string]$arg2,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardArgs
)

$BASE = if ($env:MULTIGRAVITY_HOME) { $env:MULTIGRAVITY_HOME } else { "$env:USERPROFILE\AntigravityProfiles" }

function Find-AntigravityIde {
    if ($env:MULTIGRAVITY_IDE_APP) { return $env:MULTIGRAVITY_IDE_APP }
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Antigravity IDE\Antigravity IDE.exe",
        "$env:PROGRAMFILES\Antigravity IDE\Antigravity IDE.exe",
        "${env:ProgramFiles(x86)}\Antigravity IDE\Antigravity IDE.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    $exe = Get-Command antigravity-ide.exe -ErrorAction SilentlyContinue
    if ($exe) { return $exe.Source }
    return $null
}

function Find-AntigravityChat {
    if ($env:MULTIGRAVITY_CHAT_APP) { return $env:MULTIGRAVITY_CHAT_APP }
    if ($env:MULTIGRAVITY_APP) { return $env:MULTIGRAVITY_APP }
    $paths = @(
        "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe",
        "$env:PROGRAMFILES\Antigravity\Antigravity.exe",
        "${env:ProgramFiles(x86)}\Antigravity\Antigravity.exe"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) { return $p }
    }
    $exe = Get-Command antigravity.exe -ErrorAction SilentlyContinue
    if ($exe) { return $exe.Source }
    return $null
}

function Get-DefaultIdeUserDataDir {
    return "$env:APPDATA\Antigravity IDE"
}

function Get-DefaultIdeExtensionsDir {
    return "$env:USERPROFILE\.antigravity-ide\extensions"
}

function Get-DefaultChatUserDataDir {
    return "$env:APPDATA\Antigravity"
}

function Get-DefaultChatExtensionsDir {
    return "$env:USERPROFILE\.antigravity\extensions"
}

function Get-TemplatesDir {
    return "$BASE\.templates"
}

function Test-AuthOnly {
    param($PROFILE)
    return Test-Path "$BASE\$PROFILE\.auth-only"
}

function Write-Usage {
    Write-Host "Multigravity Duo — Run multiple Antigravity IDE & Antigravity Companion profiles."
    Write-Host ""
    Write-Host "Usage: multigravity <command|profile> [options] [args...]"
    Write-Host ""
    Write-Host "Launching:"
    Write-Host "  <profile> [args...]       Launch Antigravity IDE (default)"
    Write-Host "  <profile> --chat [args..] Launch Antigravity Chat"
    Write-Host "  <profile> --all [args...] Launch BOTH Antigravity IDE & Chat"
    Write-Host "  ide <profile> [args...]   Shortcut: launch Antigravity IDE"
    Write-Host "  chat <profile> [args...]  Shortcut: launch Antigravity Chat"
    Write-Host "  all <profile> [args...]   Shortcut: launch both simultaneously"
    Write-Host ""
    Write-Host "Profile Management:"
    Write-Host "  new <name> [options]      Create a new profile & Start Menu shortcuts"
    Write-Host "      --auth-only           Share extensions & settings, isolate logins"
    Write-Host "      --from <template>     Create from a saved template"
    Write-Host "  list                      List existing profiles"
    Write-Host "  status                    Show running status, type, last used, size"
    Write-Host "  rename <old> <new>        Rename a profile (updates shortcuts)"
    Write-Host "  delete <name>             Delete a profile and its data"
    Write-Host "  clone <src> <dest>        Clone an existing profile"
    Write-Host ""
    Write-Host "Templates & Portability:"
    Write-Host "  template save <prof> <tpl> Save profile as reusable template"
    Write-Host "  template list             List available templates"
    Write-Host "  template delete <tpl>     Delete a template"
    Write-Host "  export <name> [path]      Export a profile to .zip archive"
    Write-Host "  import <archive> [name]   Import a profile from .zip archive"
    Write-Host ""
    Write-Host "Diagnostics & System:"
    Write-Host "  doctor                    Run system diagnosis for IDE & Chat"
    Write-Host "  stats                     Show storage and extension stats per profile"
    Write-Host "  update                    Update Multigravity Duo to latest version"
    Write-Host "  uninstall                 Uninstall Multigravity Duo and components"
    Write-Host "  help                      Show this help"
    Write-Host ""
    Write-Host "Profile names: alphanumeric and hyphens only (e.g. work, personal, client-1)"
}

function Validate-Name {
    param($name)
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Error "Error: profile name required"
        exit 1
    }
    if ($name -notmatch "^[a-zA-Z0-9][a-zA-Z0-9-]*$") {
        Write-Error "Error: profile name must start with alphanumeric and contain only letters, numbers, or hyphens"
        exit 1
    }
}

function Invoke-SetupSharedResources {
    param($PROFILE_DIR)

    # 1. SSH configuration & keys for Remote VMs
    $realSsh = "$env:USERPROFILE\.ssh"
    $profSsh = "$PROFILE_DIR\.ssh"
    if (Test-Path $realSsh) {
        if (!(Test-Path $profSsh)) {
            New-Item -ItemType SymbolicLink -Path $profSsh -Target $realSsh -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # 2. Git config
    $realGit = "$env:USERPROFILE\.gitconfig"
    $profGit = "$PROFILE_DIR\.gitconfig"
    if ((Test-Path $realGit) -and !(Test-Path $profGit)) {
        New-Item -ItemType SymbolicLink -Path $profGit -Target $realGit -ErrorAction SilentlyContinue | Out-Null
    }

    # 3. Gemini skills & plugins
    $realPlugins = "$env:USERPROFILE\.gemini\config\plugins"
    $profPlugins = "$PROFILE_DIR\.gemini\config\plugins"
    if (Test-Path $realPlugins) {
        New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.gemini\config" | Out-Null
        if (!(Test-Path $profPlugins)) {
            New-Item -ItemType SymbolicLink -Path $profPlugins -Target $realPlugins -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # 4. User folders (Desktop, Documents, Downloads, etc.)
    foreach ($folder in @("Desktop", "Documents", "Downloads", "Pictures", "Projects", "Development")) {
        $realFolder = "$env:USERPROFILE\$folder"
        $profFolder = "$PROFILE_DIR\$folder"
        if ((Test-Path $realFolder) -and !(Test-Path $profFolder)) {
            New-Item -ItemType SymbolicLink -Path $profFolder -Target $realFolder -ErrorAction SilentlyContinue | Out-Null
        }
    }

    # 5. Developer tools & configs (.aws, .docker, etc.)
    foreach ($tooldir in @(".aws", ".docker")) {
        $realTool = "$env:USERPROFILE\$tooldir"
        $profTool = "$PROFILE_DIR\$tooldir"
        if ((Test-Path $realTool) -and !(Test-Path $profTool)) {
            New-Item -ItemType SymbolicLink -Path $profTool -Target $realTool -ErrorAction SilentlyContinue | Out-Null
        }
    }
}

function Invoke-CreateProfileLayout {
    param($PROFILE)
    $PROFILE_DIR = "$BASE\$PROFILE"

    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.antigravity-ide\extensions" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.antigravity\extensions" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Roaming\Antigravity IDE" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Roaming\Antigravity" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Local" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.gemini" | Out-Null

    Invoke-SetupSharedResources $PROFILE_DIR
}

function Invoke-CreateAuthOnlyProfile {
    param($PROFILE)
    $PROFILE_DIR = "$BASE\$PROFILE"

    New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null
    New-Item -ItemType File -Force -Path "$PROFILE_DIR\.auth-only" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\AppData\Local" | Out-Null
    New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.gemini" | Out-Null

    # 1. Antigravity IDE Setup
    $defIdeData = Get-DefaultIdeUserDataDir
    $defIdeExt = Get-DefaultIdeExtensionsDir
    $ideDataDir = "$PROFILE_DIR\AppData\Roaming\Antigravity IDE\User"
    New-Item -ItemType Directory -Force -Path $ideDataDir | Out-Null

    if (Test-Path "$defIdeData\User") {
        foreach ($item in @("settings.json", "keybindings.json", "snippets")) {
            $src = "$defIdeData\User\$item"
            $dest = "$ideDataDir\$item"
            if ((Test-Path $src) -and !(Test-Path $dest)) {
                New-Item -ItemType SymbolicLink -Path $dest -Target $src -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    $ideExtDir = "$PROFILE_DIR\.antigravity-ide\extensions"
    if (Test-Path $defIdeExt) {
        if (Test-Path $ideExtDir) { Remove-Item $ideExtDir -Force -Recurse -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.antigravity-ide" | Out-Null
        New-Item -ItemType SymbolicLink -Path $ideExtDir -Target $defIdeExt -ErrorAction SilentlyContinue | Out-Null
    } else {
        New-Item -ItemType Directory -Force -Path $ideExtDir | Out-Null
    }

    # 2. Antigravity Chat Setup
    $defChatData = Get-DefaultChatUserDataDir
    $defChatExt = Get-DefaultChatExtensionsDir
    $chatDataDir = "$PROFILE_DIR\AppData\Roaming\Antigravity\User"
    New-Item -ItemType Directory -Force -Path $chatDataDir | Out-Null

    if (Test-Path "$defChatData\User") {
        foreach ($item in @("settings.json", "keybindings.json", "snippets")) {
            $src = "$defChatData\User\$item"
            $dest = "$chatDataDir\$item"
            if ((Test-Path $src) -and !(Test-Path $dest)) {
                New-Item -ItemType SymbolicLink -Path $dest -Target $src -ErrorAction SilentlyContinue | Out-Null
            }
        }
    }

    $chatExtDir = "$PROFILE_DIR\.antigravity\extensions"
    if (Test-Path $defChatExt) {
        if (Test-Path $chatExtDir) { Remove-Item $chatExtDir -Force -Recurse -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Force -Path "$PROFILE_DIR\.antigravity" | Out-Null
        New-Item -ItemType SymbolicLink -Path $chatExtDir -Target $defChatExt -ErrorAction SilentlyContinue | Out-Null
    } else {
        New-Item -ItemType Directory -Force -Path $chatExtDir | Out-Null
    }

    Invoke-SetupSharedResources $PROFILE_DIR
}

function Create-ShortcutLink {
    param($PROFILE, $AppType)
    $PROFILE_DIR = "$BASE\$PROFILE"
    $ProgramsFolder = [Environment]::GetFolderPath("Programs")
    $ShortcutDir = "$ProgramsFolder\Multigravity"
    New-Item -ItemType Directory -Force -Path $ShortcutDir | Out-Null

    $WScriptShell = New-Object -ComObject WScript.Shell

    $Title = if ($AppType -eq "ide") { "Multigravity $PROFILE (IDE)" } elseif ($AppType -eq "chat") { "Multigravity $PROFILE (Chat)" } else { "Multigravity $PROFILE (Duo)" }
    $Flag = if ($AppType -eq "ide") { "--ide" } elseif ($AppType -eq "chat") { "--chat" } else { "--all" }

    $Shortcut = $WScriptShell.CreateShortcut("$ShortcutDir\$Title.lnk")
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-NoProfile -WindowStyle Hidden -Command `"multigravity $PROFILE $Flag`""
    $Shortcut.WorkingDirectory = $PROFILE_DIR
    $icoPath = "$env:LOCALAPPDATA\Programs\Multigravity\icon.ico"
    if (Test-Path $icoPath) {
        $Shortcut.IconLocation = "$icoPath,0"
    }
    $Shortcut.Save()
}

function Invoke-CreateShortcuts {
    param($PROFILE)
    Create-ShortcutLink $PROFILE "ide"
    Create-ShortcutLink $PROFILE "chat"
    Create-ShortcutLink $PROFILE "duo"
    Write-Host "Created Start Menu shortcuts in 'Multigravity'"
}

function Invoke-RemoveShortcuts {
    param($PROFILE)
    $ProgramsFolder = [Environment]::GetFolderPath("Programs")
    $ShortcutDir = "$ProgramsFolder\Multigravity"
    foreach ($t in @("IDE", "Chat", "Duo")) {
        $p = "$ShortcutDir\Multigravity $PROFILE ($t).lnk"
        if (Test-Path $p) { Remove-Item -Force $p -ErrorAction SilentlyContinue }
    }
}

function Invoke-LaunchIde {
    param($PROFILE, $ArgsToForward)
    $app = Find-AntigravityIde
    if (!$app) {
        Write-Error "Error: Antigravity IDE was not found. Install it or set MULTIGRAVITY_IDE_APP."
        exit 1
    }
    $PROFILE_DIR = "$BASE\$PROFILE"
    $dataDir = "$PROFILE_DIR\AppData\Roaming\Antigravity IDE"
    $extDir = "$PROFILE_DIR\.antigravity-ide\extensions"

    Write-Host "Launching Antigravity IDE profile '$PROFILE'..."
    $cmdArgs = @("--user-data-dir", $dataDir, "--extensions-dir", $extDir)
    if ($ArgsToForward) { $cmdArgs += $ArgsToForward }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $app
    $psi.Arguments = [string]::Join(" ", $cmdArgs)
    $psi.EnvironmentVariables["USERPROFILE"] = $PROFILE_DIR
    $psi.EnvironmentVariables["APPDATA"] = "$PROFILE_DIR\AppData\Roaming"
    $psi.EnvironmentVariables["LOCALAPPDATA"] = "$PROFILE_DIR\AppData\Local"
    $psi.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}

function Invoke-LaunchChat {
    param($PROFILE, $ArgsToForward)
    $app = Find-AntigravityChat
    if (!$app) {
        Write-Error "Error: Antigravity (Chat) was not found. Install it or set MULTIGRAVITY_CHAT_APP."
        exit 1
    }
    $PROFILE_DIR = "$BASE\$PROFILE"
    $dataDir = "$PROFILE_DIR\AppData\Roaming\Antigravity"
    $extDir = "$PROFILE_DIR\.antigravity\extensions"

    Write-Host "Launching Antigravity Chat profile '$PROFILE'..."
    $cmdArgs = @("--user-data-dir", $dataDir, "--extensions-dir", $extDir)
    if ($ArgsToForward) { $cmdArgs += $ArgsToForward }

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $app
    $psi.Arguments = [string]::Join(" ", $cmdArgs)
    $psi.EnvironmentVariables["USERPROFILE"] = $PROFILE_DIR
    $psi.EnvironmentVariables["APPDATA"] = "$PROFILE_DIR\AppData\Roaming"
    $psi.EnvironmentVariables["LOCALAPPDATA"] = "$PROFILE_DIR\AppData\Local"
    $psi.UseShellExecute = $false
    [System.Diagnostics.Process]::Start($psi) | Out-Null
}

function Invoke-LaunchProfile {
    param($PROFILE, $ArgsToForward)
    $PROFILE_DIR = "$BASE\$PROFILE"

    if (!(Test-Path $PROFILE_DIR)) {
        Write-Error "Error: profile '$PROFILE' does not exist. Run: multigravity new $PROFILE"
        exit 1
    }

    if (Test-AuthOnly $PROFILE) {
        Invoke-CreateAuthOnlyProfile $PROFILE
    } else {
        Invoke-CreateProfileLayout $PROFILE
    }

    $mode = "ide"
    $cleanArgs = @()

    foreach ($a in $ArgsToForward) {
        if ($a -eq "--ide") { $mode = "ide" }
        elseif ($a -eq "--chat" -or $a -eq "--app") { $mode = "chat" }
        elseif ($a -eq "--all" -or $a -eq "--duo" -or $a -eq "--both") { $mode = "all" }
        else { $cleanArgs += $a }
    }

    if ($mode -eq "ide") {
        Invoke-LaunchIde $PROFILE $cleanArgs
    } elseif ($mode -eq "chat") {
        Invoke-LaunchChat $PROFILE $cleanArgs
    } elseif ($mode -eq "all") {
        Invoke-LaunchIde $PROFILE $cleanArgs
        Invoke-LaunchChat $PROFILE $cleanArgs
    }
}

# --- Command Router ---
switch ($cmd) {
    "help" { Write-Usage }
    "-h"   { Write-Usage }
    "--help" { Write-Usage }
    ""     { Write-Usage }

    "list" {
        Write-Host "Existing profiles:"
        if (Test-Path $BASE) {
            $profs = Get-ChildItem -Directory -Path $BASE | Where-Object { $_.Name -ne ".templates" }
            if ($profs.Count -eq 0) { Write-Host "  (none)" }
            foreach ($p in $profs) { Write-Host "  $($p.Name)" }
        } else {
            Write-Host "  (none)"
        }
    }

    "new" {
        $pName = $arg1
        $authOnly = $false
        $fromTpl = $null

        $remaining = @($arg2) + $ForwardArgs
        for ($i = 0; $i -lt $remaining.Length; $i++) {
            if ($remaining[$i] -eq "--auth-only") { $authOnly = $true }
            elseif ($remaining[$i] -eq "--from" -and ($i + 1) -lt $remaining.Length) {
                $fromTpl = $remaining[$i + 1]
                $i++
            }
        }

        Validate-Name $pName
        $pDir = "$BASE\$pName"
        if (Test-Path $pDir) {
            Write-Error "Error: profile '$pName' already exists."
            exit 1
        }

        New-Item -ItemType Directory -Force -Path $BASE | Out-Null

        if ($fromTpl) {
            $tplDir = "$(Get-TemplatesDir)\$fromTpl"
            if (!(Test-Path $tplDir)) {
                Write-Error "Error: template '$fromTpl' does not exist."
                exit 1
            }
            Copy-Item -Path $tplDir -Destination $pDir -Recurse
        } elseif ($authOnly) {
            Invoke-CreateAuthOnlyProfile $pName
        } else {
            Invoke-CreateProfileLayout $pName
        }

        Write-Host "Created profile '$pName'"
        Invoke-CreateShortcuts $pName
    }

    "ide" {
        if (!$arg1) { Write-Error "Error: profile name required. Run: multigravity ide <profile>"; exit 1 }
        Invoke-LaunchProfile $arg1 (@("--ide") + $ForwardArgs)
    }

    "chat" {
        if (!$arg1) { Write-Error "Error: profile name required. Run: multigravity chat <profile>"; exit 1 }
        Invoke-LaunchProfile $arg1 (@("--chat") + $ForwardArgs)
    }

    "all" {
        if (!$arg1) { Write-Error "Error: profile name required. Run: multigravity all <profile>"; exit 1 }
        Invoke-LaunchProfile $arg1 (@("--all") + $ForwardArgs)
    }

    "delete" {
        Validate-Name $arg1
        $pDir = "$BASE\$arg1"
        if (!(Test-Path $pDir)) { Write-Error "Error: profile '$arg1' does not exist."; exit 1 }
        $resp = Read-Host "Delete profile '$arg1' and all its data? [y/N]"
        if ($resp -match "^[yY]$") {
            Remove-Item -Path $pDir -Recurse -Force
            Invoke-RemoveShortcuts $arg1
            Write-Host "Deleted profile '$arg1'"
        } else {
            Write-Host "Aborted."
        }
    }

    "rename" {
        Validate-Name $arg1
        Validate-Name $arg2
        $src = "$BASE\$arg1"
        $dest = "$BASE\$arg2"
        if (!(Test-Path $src)) { Write-Error "Error: profile '$arg1' does not exist."; exit 1 }
        if (Test-Path $dest) { Write-Error "Error: profile '$arg2' already exists."; exit 1 }

        Rename-Item -Path $src -NewName $arg2
        Invoke-RemoveShortcuts $arg1
        Invoke-CreateShortcuts $arg2
        Write-Host "Renamed profile '$arg1' to '$arg2'"
    }

    "clone" {
        Validate-Name $arg1
        Validate-Name $arg2
        $src = "$BASE\$arg1"
        $dest = "$BASE\$arg2"
        if (!(Test-Path $src)) { Write-Error "Error: profile '$arg1' does not exist."; exit 1 }
        if (Test-Path $dest) { Write-Error "Error: profile '$arg2' already exists."; exit 1 }

        Copy-Item -Path $src -Destination $dest -Recurse
        Invoke-CreateShortcuts $arg2
        Write-Host "Successfully cloned '$arg1' to '$arg2'"
    }

    "status" {
        if (!(Test-Path $BASE)) { Write-Host "No profiles found."; exit 0 }
        $profs = Get-ChildItem -Directory -Path $BASE | Where-Object { $_.Name -ne ".templates" }
        Write-Host ("{0,-16} {1,-10} {2,-10} {3,-10} {4,-18} {5}" -f "PROFILE", "IDE", "CHAT", "TYPE", "LAST USED", "SIZE")
        Write-Host ("{0,-16} {1,-10} {2,-10} {3,-10} {4,-18} {5}" -f "-------", "---", "----", "----", "---------", "----")

        foreach ($p in $profs) {
            $ideData = "$($p.FullName)\AppData\Roaming\Antigravity IDE"
            $chatData = "$($p.FullName)\AppData\Roaming\Antigravity"

            $ideProc = Get-Process -Name "Antigravity IDE" -ErrorAction SilentlyContinue
            $chatProc = Get-Process -Name "Antigravity" -ErrorAction SilentlyContinue

            $ideStatus = if ($ideProc) { "running" } else { "stopped" }
            $chatStatus = if ($chatProc) { "running" } else { "stopped" }
            $pType = if (Test-Path "$($p.FullName)\.auth-only") { "auth-only" } else { "full" }
            $lastUsed = $p.LastWriteTime.ToString("yyyy-MM-dd HH:mm")

            $bytes = (Get-ChildItem -Path $p.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            $size = if ($bytes -ge 1GB) { "{0:N1} GB" -f ($bytes / 1GB) } elseif ($bytes -ge 1MB) { "{0:N1} MB" -f ($bytes / 1MB) } else { "{0:N0} KB" -f ($bytes / 1KB) }

            Write-Host ("{0,-16} {1,-10} {2,-10} {3,-10} {4,-18} {5}" -f $p.Name, $ideStatus, $chatStatus, $pType, $lastUsed, $size)
        }
    }

    "doctor" {
        Write-Host "Checking Multigravity Duo Windows environment..."
        $ide = Find-AntigravityIde
        $chat = Find-AntigravityChat

        if ($ide) { Write-Host "  [✓] Antigravity IDE: Found at $ide" } else { Write-Host "  [!] Antigravity IDE: Not found" }
        if ($chat) { Write-Host "  [✓] Antigravity Chat: Found at $chat" } else { Write-Host "  [!] Antigravity Chat: Not found" }
        if (Test-Path $BASE) { Write-Host "  [✓] Profile storage: $BASE (available)" } else { Write-Host "  [!] Profile storage: $BASE (not yet created)" }
        Write-Host ""
        Write-Host "Doctor check complete."
    }

    "uninstall" {
        $resp = Read-Host "Are you sure you want to uninstall Multigravity Duo? [y/N]"
        if ($resp -notmatch "^[yY]$") { Write-Host "Aborted."; exit 0 }

        # Remove Start Menu shortcuts
        $ProgramsFolder = [Environment]::GetFolderPath("Programs")
        $ShortcutDir = "$ProgramsFolder\Multigravity"
        if (Test-Path $ShortcutDir) {
            Remove-Item -Path $ShortcutDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Removed Start Menu shortcuts."
        }

        # Check profiles
        $baseDir = if ($env:MULTIGRAVITY_HOME) { $env:MULTIGRAVITY_HOME } else { "$env:USERPROFILE\AntigravityProfiles" }
        if (Test-Path $baseDir) {
            Write-Host ""
            $pResp = Read-Host "Do you also want to permanently delete all profile data in $baseDir? [y/N]"
            if ($pResp -match "^[yY]$") {
                Remove-Item -Path $baseDir -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "Deleted profile directory: $baseDir"
            } else {
                Write-Host "Kept profile directory: $baseDir"
            }
        }

        # Remove installation dir and PATH
        $InstallDir = "$env:LOCALAPPDATA\Programs\Multigravity"
        $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
        if ($userPath -like "*$InstallDir*") {
            $parts = $userPath -split ';' | Where-Object { $_ -ne $InstallDir -and $_ -ne "$InstallDir\" -and $_ -ne "" }
            $newPath = $parts -join ';'
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            Write-Host "Removed $InstallDir from user PATH."
        }
        if (Test-Path $InstallDir) {
            Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Removed $InstallDir."
        }
        Write-Host "✓ Multigravity Duo uninstalled successfully!"
    }

    default {
        # Profile launch
        $fArgs = @()
        if ($arg1) { $fArgs += $arg1 }
        if ($arg2) { $fArgs += $arg2 }
        if ($ForwardArgs) { $fArgs += $ForwardArgs }
        Invoke-LaunchProfile $cmd $fArgs
    }
}
