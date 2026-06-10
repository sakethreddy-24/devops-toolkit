#!/bin/bash
# install.sh — Install devops-toolkit to system PATH

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
TOOLKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing devops-toolkit..."

# Make all scripts executable
chmod +x "$TOOLKIT_DIR/devops-toolkit"
chmod +x "$TOOLKIT_DIR/tools/"*.sh
chmod +x "$TOOLKIT_DIR/lib/common.sh"

# Create symlink in PATH
ln -sf "$TOOLKIT_DIR/devops-toolkit" "$INSTALL_DIR/devops-toolkit"

echo "✓ Installed successfully"
echo "✓ Run from anywhere: devops-toolkit"
