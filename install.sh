#!/bin/bash
set -euo pipefail

REPO="rakibkhanofficial/multigravity-duo"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
INSTALL_DIR="/usr/local/bin"

print_step () { echo "  → $1"; }
abort ()       { echo "Error: $1" >&2; exit 1; }

case "$(uname -s)" in
  Darwin)
    PLATFORM="darwin"
    ;;
  Linux)
    PLATFORM="linux"
    ;;
  *)
    abort "unsupported platform. Multigravity Duo currently supports macOS and Linux."
    ;;
esac

command -v curl &>/dev/null || abort "curl is required but not found"

if [ ! -w "$INSTALL_DIR" ]; then
  INSTALL_DIR="$HOME/.local/bin"
  mkdir -p "$INSTALL_DIR"
  if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Warning: $INSTALL_DIR is not in your PATH."
    echo "  Add this to your shell profile (~/.zshrc or ~/.bashrc):"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
  fi
fi

echo "======================================================"
echo " Installing Multigravity Duo (IDE & Companion edition)"
echo " Target directory: $INSTALL_DIR"
echo "======================================================"

# Download script
print_step "Downloading multigravity CLI..."
curl -fsSL "$RAW/multigravity" -o "$INSTALL_DIR/multigravity"
chmod +x "$INSTALL_DIR/multigravity"

# Download macOS icon if darwin
if [ "$PLATFORM" = "darwin" ]; then
  print_step "Downloading application icon..."
  curl -fsSL "$RAW/icon.icns" -o "$INSTALL_DIR/icon.icns" || true
fi

echo ""
echo "✓ Multigravity Duo installed successfully!"
echo ""
echo "Getting Started:"
echo "  multigravity doctor                # Verify Antigravity IDE & Chat setup"
echo "  multigravity new <profile-name>    # Create a profile with launchers"
echo "  multigravity <profile-name>        # Launch Antigravity IDE"
echo "  multigravity <profile-name> --chat # Launch Antigravity Companion (Chat)"
echo "  multigravity <profile-name> --all  # Launch both simultaneously"
echo ""
echo "Full documentation: https://github.com/$REPO"
