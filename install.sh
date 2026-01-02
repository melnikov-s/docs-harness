#!/usr/bin/env bash
#
# docs-harness installer
# 
# One-liner:
#   curl -fsSL https://raw.githubusercontent.com/melnikov-s/docs-harness/main/install.sh | bash
#

set -euo pipefail

# Colors
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    NC=''
fi

REPO_RAW="https://raw.githubusercontent.com/melnikov-s/docs-harness/main"
INSTALL_DIR="${HOME}/.local/share/docs-harness"
BIN_DIR="${HOME}/.local/bin"

# Detect if updating or fresh install
if [[ -f "$INSTALL_DIR/docs-harness.sh" ]]; then
    UPDATING=true
else
    UPDATING=false
fi

echo "Installing docs-harness..."

# Create directories
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Download the main script (overwrites existing)
curl -fsSL "${REPO_RAW}/docs-harness.sh" -o "$INSTALL_DIR/docs-harness.sh"
chmod +x "$INSTALL_DIR/docs-harness.sh"

# Create symlink in bin (force overwrites existing)
ln -sf "$INSTALL_DIR/docs-harness.sh" "$BIN_DIR/docs-harness"

if $UPDATING; then
    echo -e "${GREEN}✓${NC} Updated docs-harness to latest version"
else
    echo -e "${GREEN}✓${NC} Installed docs-harness"
fi

# Check if ~/.local/bin is in PATH
if echo "$PATH" | grep -q "$BIN_DIR"; then
    echo ""
    echo -e "${GREEN}Ready!${NC} Run 'docs-harness' in any repository."
else
    echo ""
    echo -e "${YELLOW}Add to PATH:${NC}"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "Add that to ~/.zshrc or ~/.bashrc, then restart your shell."
fi
