# Multigravity Duo

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/rakibkhanofficial/multigravity-duo)
[![GitHub Profile](https://img.shields.io/badge/Author-Rakib_Khan-purple?logo=github)](https://github.com/rakibkhanofficial)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS_%7C_Linux_%7C_Windows-lightgrey.svg)]()
[![Apps Supported](https://img.shields.io/badge/Dual_Support-Antigravity_IDE_+_Companion-orange.svg)]()

<div align="center">
  <img src="assets/multigravity-logo.jpg" alt="Multigravity Duo" width="90" style="border-radius: 16px;">
  <h3>Simultaneous Multi-Account Profile Manager for Google Antigravity IDE & Companion</h3>
  <p>Run multiple isolated Google Antigravity environments concurrently with dedicated accounts, workspaces, and extensions.</p>
</div>

---

## 🚀 The Dual-App Architecture

Google Antigravity provides two distinct applications:
1. **Antigravity IDE** (`Antigravity IDE.app`): The full agentic coding workspace and development environment.
2. **Antigravity Companion / Chat** (`Antigravity.app`): The dedicated AI chat, project manager, and cloud agent window.

Legacy profile switchers only knew how to clone the single older Antigravity app. **Multigravity Duo** was built from the ground up to orchestrate **both applications together**:

- **Dual-App Profile Isolation**: Each profile provisions dedicated, isolated user-data and extension directories for both **Antigravity IDE** and **Antigravity Companion**.
- **Flexible Launch Control**: Open just the IDE (`multigravity work`), just the companion chat (`multigravity work --chat`), or spin up both at the same time (`multigravity work --all`).
- **One-Click Native Shortcuts**: Automatically generates macOS `.app` bundles, Linux `.desktop` entries, and Windows Start Menu shortcuts for each profile.
- **Ultra-Slim Auth-Only Mode**: Share extensions and settings while isolating only Google accounts and authentication tokens (~2 MB vs ~500 MB).

---

## 📦 Quick Installation

### macOS & Linux
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rakibkhanofficial/multigravity-duo/main/install.sh)"
```

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/rakibkhanofficial/multigravity-duo/main/install.ps1 | iex
```

Verify your environment anytime:
```bash
multigravity doctor
```

---

## ⚡ Getting Started

### 1. Create a Profile
Create a profile for each account, client, or team:
```bash
multigravity new personal
multigravity new work
multigravity new client-a --auth-only
```

Each profile automatically provisions native launcher shortcuts:
- **macOS**: 
  - `~/Applications/Multigravity <name> IDE.app` (Launches Antigravity IDE)
  - `~/Applications/Multigravity <name>.app` (Launches Antigravity Companion)
  - `~/Applications/Multigravity <name> Duo.app` (Launches both simultaneously)
- **Linux**:
  - `~/.local/share/applications/multigravity-<name>-ide.desktop`
  - `~/.local/share/applications/multigravity-<name>-chat.desktop`
  - `~/.local/share/applications/multigravity-<name>-duo.desktop`
- **Windows**:
  - Start Menu shortcuts for `(IDE)`, `(Chat)`, and `(Duo)`

---

### 2. Launching Profiles

#### Launch Antigravity IDE (Default)
```bash
multigravity work
multigravity work .
multigravity work /path/to/project
```

#### Launch Antigravity Companion (Chat)
```bash
multigravity work --chat
# or shorthand:
multigravity chat work
```

#### Launch Both Simultaneously (Duo Mode)
```bash
multigravity work --all
# or shorthand:
multigravity all work
```

---

## 🛡️ Auth-Only Mode (Save 99% Storage)

If you only need separate Google logins without duplicating multi-gigabyte extension directories, use `--auth-only`:

```bash
multigravity new freelance --auth-only
```

| Feature | Full Profile | Auth-Only Profile |
| :--- | :--- | :--- |
| **Antigravity IDE Extensions** | Separate copy | Shared via symlink |
| **Companion Extensions** | Separate copy | Shared via symlink |
| **Settings & Keybindings** | Independent copy | Symlinked from default |
| **Google Logins & Cookies** | **100% Isolated** | **100% Isolated** |
| **Approximate Disk Space** | ~500 MB – 1.5 GB | ~2 MB |

---

## 📊 Live Status & Diagnostics

### Real-Time Status Dashboard
View active running instances, profile types, last modified times, and disk footprints:
```bash
multigravity status
```
```text
PROFILE          IDE          CHAT         TYPE       LAST USED          SIZE
-------          ---          ----         ----       ---------          ----
work             running      running      full       2026-10-07 13:20   512 MB
personal         running      stopped      full       2026-10-07 12:45   480 MB
client-a         stopped      stopped      auth-only  2026-10-07 11:10   2 MB
```

### Storage Breakdown
```bash
multigravity stats
```
```text
Multigravity Duo Profile Storage Breakdown:
PROFILE            TOTAL      IDE EXT      CHAT EXT     TYPE
-------            -----      -------      --------     ----
work               512 MB     18           12           full
personal           480 MB     16           10           full
client-a           2 MB       18 (shared)  12 (shared)  auth-only

Total usage: 994 MB
```

### Environment Doctor
```bash
multigravity doctor
```
```text
Checking Multigravity Duo environment...
  [✓] Platform: darwin
  [✓] Antigravity IDE: Found at /Applications/Antigravity IDE.app
  [✓] Antigravity (Chat): Found at /Applications/Antigravity.app
  [✓] Global Binary: /usr/local/bin/multigravity
  [✓] Application Icon: Found
  [✓] Profile storage: /Users/username/AntigravityProfiles (writable)

✓ Your Multigravity Duo environment looks perfect!
```

---

## 🔄 Templates & Portability

### Save & Reuse Templates
```bash
# Save an existing configured profile as a template:
multigravity template save work dev-template

# Inspect available templates:
multigravity template list

# Spin up a new profile pre-loaded with your template:
multigravity new staging --from dev-template
```

### Export & Import Across Machines
```bash
# Export to compressed archive (macOS/Linux: .tar.gz, Windows: .zip)
multigravity export work ~/Desktop/work-backup.tar.gz

# Import into another machine:
multigravity import ~/Desktop/work-backup.tar.gz
multigravity import ~/Desktop/work-backup.tar.gz custom-name
```

---

## 📖 Command Reference

| Command | Description |
| :--- | :--- |
| `multigravity <name> [args...]` | Launch Antigravity IDE with profile |
| `multigravity <name> --chat` | Launch Antigravity Companion with profile |
| `multigravity <name> --all` | Launch both IDE and Companion together |
| `multigravity ide <name>` | Shortcut to launch IDE |
| `multigravity chat <name>` | Shortcut to launch Companion |
| `multigravity all <name>` | Shortcut to launch both |
| `multigravity new <name> [--auth-only]` | Create profile and desktop shortcuts |
| `multigravity list` | List all existing profiles |
| `multigravity status` | Show running status for both IDE & Companion |
| `multigravity clone <src> <dest>` | Duplicate an existing profile |
| `multigravity rename <old> <new>` | Rename profile and regenerate shortcuts |
| `multigravity delete <name>` | Delete profile and remove shortcuts |
| `multigravity template save <prof> <tpl>` | Save profile as a blueprint template |
| `multigravity template list` | List saved templates |
| `multigravity template delete <tpl>` | Remove template |
| `multigravity export <name> [path]` | Export profile to portable archive |
| `multigravity import <archive> [name]` | Import profile from archive |
| `multigravity doctor` | Diagnose paths, binaries, and environment |
| `multigravity stats` | Disk space & extension usage breakdown |
| `multigravity completion [zsh\|bash]` | Generate shell autocomplete scripts |
| `multigravity update` | Update Multigravity Duo to latest version |
| `multigravity uninstall` | Uninstall CLI and remove launchers |

---

## 🗑️ Profile Deletion & Uninstallation

If you need to remove individual profiles or completely uninstall Multigravity Duo from your system, follow the steps below:

### 1. Delete Profiles

#### Using Multigravity CLI (Recommended)
You can delete profiles anytime using the `delete` command. This removes the isolated profile folder, cache, and all associated native desktop launcher shortcuts:

```bash
# Example: Delete the 'work' and 'personal' profiles
multigravity delete work
multigravity delete personal

# Verify remaining profiles
multigravity list
```

#### Manual Profile & Shortcut Deletion (macOS, Linux, Windows)
If you have already removed the CLI or want to manually wipe profile directories and shortcuts:

- **macOS**:
  ```bash
  # Delete a specific profile (e.g. work)
  rm -rf ~/AntigravityProfiles/work

  # Delete all profiles and data
  rm -rf ~/AntigravityProfiles

  # Delete native launcher shortcuts
  rm -rf ~/Applications/Multigravity*.app
  ```

- **Linux**:
  ```bash
  # Delete a specific profile (e.g. work)
  rm -rf ~/AntigravityProfiles/work

  # Delete all profiles and data
  rm -rf ~/AntigravityProfiles

  # Delete desktop shortcuts and launcher scripts
  rm -f ~/.local/share/applications/multigravity-*.desktop
  rm -rf ~/.local/share/multigravity
  ```

- **Windows (PowerShell)**:
  ```powershell
  # Delete a specific profile (e.g. work)
  Remove-Item -Recurse -Force "$env:USERPROFILE\AntigravityProfiles\work"

  # Delete all profiles and data
  Remove-Item -Recurse -Force "$env:USERPROFILE\AntigravityProfiles"

  # Delete Start Menu shortcuts
  Remove-Item -Recurse -Force "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Multigravity"
  ```

---

### 2. Uninstall Multigravity CLI

If you want to completely remove the Multigravity CLI tool itself:

#### Automated Uninstall Script (One-Liner)

- **macOS & Linux**:
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/rakibkhanofficial/multigravity-duo/main/uninstall.sh)"
  ```

- **Windows (PowerShell)**:
  ```powershell
  irm https://raw.githubusercontent.com/rakibkhanofficial/multigravity-duo/main/uninstall.ps1 | iex
  ```

*(Or simply run `multigravity uninstall` if the CLI is already installed in your PATH.)*

#### Manual CLI Removal

- **macOS & Linux**:
  ```bash
  # Remove binary and icon from /usr/local/bin
  sudo rm -f /usr/local/bin/multigravity /usr/local/bin/icon.icns

  # Or if installed in ~/.local/bin:
  rm -f ~/.local/bin/multigravity ~/.local/bin/icon.icns
  ```

- **Windows (PowerShell)**:
  ```powershell
  # Remove application directory
  Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Programs\Multigravity"

  # Clean user PATH environment variable
  $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
  $newPath = ($userPath -split ';' | Where-Object { $_ -ne "$env:LOCALAPPDATA\Programs\Multigravity" -and $_ -ne "" }) -join ';'
  [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
  ```

---

## ⚙️ Environment Overrides

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `MULTIGRAVITY_IDE_APP` | Auto-detected | Custom path to Antigravity IDE executable/bundle |
| `MULTIGRAVITY_CHAT_APP` | Auto-detected | Custom path to Antigravity Companion app |
| `MULTIGRAVITY_HOME` | `~/AntigravityProfiles` | Base directory for storing profile data |

---

## 👤 Author & Contributing

Created with ❤️ by **Rakib Khan** ([@rakibkhanofficial](https://github.com/rakibkhanofficial)).

Issues and pull requests are warmly welcome! If you find Multigravity Duo helpful, please star the repository!

## 📄 License

This project is licensed under the [MIT License](LICENSE).
