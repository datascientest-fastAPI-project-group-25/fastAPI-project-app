#!/bin/bash
# Setup script for the VERSION file merge driver
# Run this script once to configure Git to use the custom merge driver

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Setting up custom merge driver for VERSION file..."

# Configure Git to use our custom merge driver
git config --local merge.version-merge.name "Custom VERSION file merge driver"
git config --local merge.version-merge.driver "$REPO_ROOT/scripts/version-management/version-merge.sh %O %A %B"

echo "✅ Setup complete!"
echo "The VERSION file will now automatically resolve merge conflicts by keeping the higher version number."
