#!/bin/bash

# Script to enable a specific GitHub Actions workflow by removing the .disabled extension

if [ $# -ne 1 ]; then
  echo "Usage: $0 <workflow_file_path>"
  echo "Example: $0 .github/workflows/main-branch.yml.disabled"
  exit 1
fi

WORKFLOW_PATH="$1"

if [[ ! -f "$WORKFLOW_PATH" ]]; then
  echo "Error: Workflow file not found: $WORKFLOW_PATH"
  exit 1
fi

if [[ "$WORKFLOW_PATH" != *.disabled ]]; then
  echo "Error: File does not have .disabled extension: $WORKFLOW_PATH"
  exit 1
fi

# Remove .disabled extension
NEW_PATH="${WORKFLOW_PATH%.disabled}"
mv "$WORKFLOW_PATH" "$NEW_PATH"

echo "Workflow enabled: $NEW_PATH"
