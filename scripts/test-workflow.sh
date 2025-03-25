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

# Detect platform and set appropriate flags
PLATFORM_FLAGS=""
if [[ "$(uname)" == "Darwin" ]]; then
  PLATFORM_FLAGS="--platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest"
fi

# Check if .secrets file exists, if not create it with default values
if [ ! -f ".secrets" ]; then
  echo "Creating .secrets file with default values..."
  cat >.secrets <<EOL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=app
GITHUB_TOKEN=test-token
EOL
fi

# Check if pnpm-lock.yaml exists in frontend
if [ ! -f "frontend/pnpm-lock.yaml" ]; then
  echo "Warning: frontend/pnpm-lock.yaml not found. Converting from package-lock.json..."
  (cd frontend && rm -f package-lock.json && pnpm install)
fi

echo "Testing workflow: $WORKFLOW_FILE with event: $EVENT_TYPE"
echo "=================================================="

# Run the workflow with act
echo "Running: act $EVENT_TYPE -W .github/workflows/$WORKFLOW_FILE $PLATFORM_FLAGS --verbose"
act $EVENT_TYPE -W .github/workflows/$WORKFLOW_FILE $PLATFORM_FLAGS --verbose || {
  echo "Error: act command failed or timed out"
  echo "You can try:"
  echo "1. Running with specific jobs: act $EVENT_TYPE -W .github/workflows/$WORKFLOW_FILE -j <job_id>"
  echo "2. Running with --privileged flag if Docker permissions are needed"
  echo "3. Check if all required secrets are set in .secrets file"
  echo "4. Check if all required dependencies are installed"
  exit 1
}

echo "=================================================="
echo "Workflow test complete"
