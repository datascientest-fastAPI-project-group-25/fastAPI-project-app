#!/bin/bash

# Script to disable all GitHub Actions workflows by renaming them with .disabled extension

WORKFLOWS_DIR=".github/workflows"

# Find all workflow files and rename them
find "$WORKFLOWS_DIR" -name "*.yml" -type f | while read -r workflow; do
  echo "Disabling workflow: $workflow"
mv "$workflow" "${workflow}.disabled"
if [ $? -ne 0 ]; then
  echo "Error disabling workflow: $workflow"
  exit 1
fi
done

echo "All workflows have been disabled."
