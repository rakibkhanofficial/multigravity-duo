#!/bin/bash
set -euo pipefail

REPO="rakibkhanofficial/multigravity-duo"
print_step () { echo "  → $1"; }

echo "======================================================"
echo " Uninstalling Multigravity Duo (CLI & Components)"
echo "======================================================"

# 1. Remove binary and icon from /usr/local/bin or ~/.local/bin
REMOVED=0
for BIN_DIR in "/usr/local/bin" "$HOME/.local/bin"; do
  if [ -f "$BIN_DIR/multigravity" ]; then
    print_step "Removing multigravity CLI from $BIN_DIR..."
    if [ -w "$BIN_DIR/multigravity" ]; then
      rm -f "$BIN_DIR/multigravity"
    else
      echo "  Root permissions required to remove $BIN_DIR/multigravity:"
      sudo rm -f "$BIN_DIR/multigravity"
    fi
    REMOVED=1
  fi
  if [ -f "$BIN_DIR/icon.icns" ]; then
    if [ -w "$BIN_DIR/icon.icns" ]; then
      rm -f "$BIN_DIR/icon.icns"
    else
      sudo rm -f "$BIN_DIR/icon.icns" 2>/dev/null || true
    fi
  fi
done

if [ $REMOVED -eq 0 ]; then
  echo "  (multigravity binary not found in standard directories)"
fi

# 2. Clean up desktop shortcuts and launchers
case "$(uname -s)" in
  Darwin)
    if ls "$HOME/Applications"/Multigravity*.app 1>/dev/null 2>&1; then
      print_step "Removing macOS launcher apps from ~/Applications..."
      rm -rf "$HOME/Applications"/Multigravity*.app
    fi
    ;;
  Linux)
    if ls "$HOME/.local/share/applications"/multigravity-*.desktop 1>/dev/null 2>&1; then
      print_step "Removing Linux desktop shortcuts..."
      rm -f "$HOME/.local/share/applications"/multigravity-*.desktop
    fi
    if [ -d "$HOME/.local/share/multigravity" ]; then
      print_step "Removing Linux launcher scripts..."
      rm -rf "$HOME/.local/share/multigravity"
    fi
    ;;
esac

echo ""
# 3. Check for profile data directory
PROFILE_DIR="${MULTIGRAVITY_HOME:-$HOME/AntigravityProfiles}"
if [ -d "$PROFILE_DIR" ]; then
  echo "Notice: Your profile data directory still exists at:"
  echo "  $PROFILE_DIR"
  echo ""
  read -r -p "Do you want to permanently delete all profile data and accounts? [y/N] " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$PROFILE_DIR"
    print_step "Deleted profile directory: $PROFILE_DIR"
  else
    echo "  Kept profile directory: $PROFILE_DIR"
  fi
fi

echo ""
echo "✓ Multigravity Duo uninstalled successfully!"
