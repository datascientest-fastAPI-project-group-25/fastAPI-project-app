#!/bin/bash

# Script to re-enable branch protection for main and stg branches
# This script restores the original pre-commit config and removes the disabled file

echo "🔒 Re-enabling branch protection..."
echo ""

# Restore the original pre-commit config
PRE_COMMIT_CONFIG=".pre-commit-config.yaml"
PRE_COMMIT_CONFIG_BACKUP=".pre-commit-config.yaml.bak"

if [ -f "$PRE_COMMIT_CONFIG_BACKUP" ]; then
    mv "$PRE_COMMIT_CONFIG_BACKUP" "$PRE_COMMIT_CONFIG"
    echo "✅ Restored original pre-commit config from $PRE_COMMIT_CONFIG_BACKUP"
else
    echo "❌ Backup pre-commit config not found at $PRE_COMMIT_CONFIG_BACKUP"
    echo "Branch protection may not have been disabled or the backup file was removed."
fi

# Remove the disabled file
DISABLED_FILE=".github/workflows/disabled"
if [ -f "$DISABLED_FILE" ]; then
    rm -f "$DISABLED_FILE"
    echo "✅ Removed $DISABLED_FILE to re-enable GitHub Actions workflows"
else
    echo "❌ Disabled file not found at $DISABLED_FILE"
    echo "GitHub Actions workflows may not have been disabled."
fi

echo ""
echo "Branch protection has been re-enabled."
echo "Pushes to main and stg branches will now be blocked by pre-commit hooks."
echo "GitHub Actions workflows will now run normally."
echo ""
