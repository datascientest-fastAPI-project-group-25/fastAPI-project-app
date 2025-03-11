#!/bin/bash
# Script to test GitHub Actions workflows locally using act
# Usage: ./scripts/test-workflow.sh <workflow-file> [event-type]

set -e

# Default event type is push
EVENT_TYPE=${2:-push}
WORKFLOW_FILE=$1

if [ -z "$WORKFLOW_FILE" ]; then
  echo "Error: Workflow file not specified"
  echo "Usage: ./scripts/test-workflow.sh <workflow-file> [event-type]"
  echo "Example: ./scripts/test-workflow.sh feature-branch-checks.yml push"
  exit 1
fi

# Check if the workflow file exists
if [ ! -f ".github/workflows/$WORKFLOW_FILE" ]; then
  echo "Error: Workflow file .github/workflows/$WORKFLOW_FILE not found"
  exit 1
fi

echo "Testing workflow: $WORKFLOW_FILE with event: $EVENT_TYPE"
echo "=================================================="

# Run the workflow with act
act $EVENT_TYPE -W .github/workflows/$WORKFLOW_FILE

echo "=================================================="
echo "Workflow test complete"
