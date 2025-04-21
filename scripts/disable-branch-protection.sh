#!/bin/bash

# Script to disable branch protection for direct pushes to main or stg branches
# This is a temporary solution for emergency situations

echo "⚠️ WARNING: This script will disable branch protection mechanisms ⚠️"
echo "This should only be used in emergency situations when you need to push directly to protected branches."
echo "Remember to re-enable branch protection after your work is done."
echo ""

# Disable pre-commit hooks temporarily
echo "Disabling pre-commit hooks..."
PRE_COMMIT_CONFIG=".pre-commit-config.yaml"
PRE_COMMIT_CONFIG_BACKUP=".pre-commit-config.yaml.bak"

# Backup the original pre-commit config
if [ -f "$PRE_COMMIT_CONFIG" ]; then
    cp "$PRE_COMMIT_CONFIG" "$PRE_COMMIT_CONFIG_BACKUP"
    echo "✅ Backed up pre-commit config to $PRE_COMMIT_CONFIG_BACKUP"
else
    echo "❌ Pre-commit config not found at $PRE_COMMIT_CONFIG"
    exit 1
fi

# Comment out the block-main-push hook in the pre-commit config
sed -i.tmp '/id: block-main-push/,/stages: \[pre-push\]/s/^/#/' "$PRE_COMMIT_CONFIG"
rm -f "$PRE_COMMIT_CONFIG.tmp"
echo "✅ Disabled block-main-push hook in pre-commit config"

# Create a .github/workflows/disabled file to indicate that workflows should be skipped
WORKFLOWS_DIR=".github/workflows"
DISABLED_FILE="$WORKFLOWS_DIR/disabled"

if [ -d "$WORKFLOWS_DIR" ]; then
    echo "Disabling GitHub Actions workflows..."
    touch "$DISABLED_FILE"
    echo "# This file indicates that GitHub Actions workflows should be skipped" > "$DISABLED_FILE"
    echo "# It was created by the disable-branch-protection.sh script" >> "$DISABLED_FILE"
    echo "# Remove this file to re-enable GitHub Actions workflows" >> "$DISABLED_FILE"
    echo "disabled_at=$(date)" >> "$DISABLED_FILE"
    echo "✅ Created $DISABLED_FILE to disable GitHub Actions workflows"
else
    echo "❌ GitHub workflows directory not found at $WORKFLOWS_DIR"
fi

echo ""
echo "Branch protection has been temporarily disabled."
echo "You can now push directly to main or stg branches."
echo ""
echo "To skip GitHub Actions workflows when pushing, use:"
echo "  git push -o ci.skip"
echo ""
echo "To re-enable branch protection, run:"
echo "  mv $PRE_COMMIT_CONFIG_BACKUP $PRE_COMMIT_CONFIG"
echo "  rm -f $DISABLED_FILE"
echo ""
echo "⚠️ IMPORTANT: Remember to re-enable branch protection after your work is done! ⚠️"
