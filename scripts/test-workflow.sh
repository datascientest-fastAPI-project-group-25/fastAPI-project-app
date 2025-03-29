#!/bin/bash
# Script to test GitHub Actions workflows locally using act
# Usage: ./scripts/test-workflow.sh <workflow-file> [event-type]

set -e

# Default event type is push
EVENT_TYPE=${2:-push}
WORKFLOW_FILE=$(realpath "$1")

if [ -z "$WORKFLOW_FILE" ]; then
  echo "Error: Workflow file not specified"
  echo "Usage: ./scripts/test-workflow.sh <workflow-file> [event-type]"
  echo "Example: ./scripts/test-workflow.sh feature-branch-checks.yml push"
  exit 1
fi

# Check if the workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: Workflow file not found: $WORKFLOW_FILE"
  exit 1
fi

# Detect platform and set appropriate flags
PLATFORM_FLAGS=""
if [[ "$(uname)" == "Darwin" ]]; then
  PLATFORM_FLAGS="--platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest"
fi

# Check if .env file exists, if not use .env.example
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  if [ -f ".env.example" ]; then
    ENV_FILE=".env.example"
    echo "Using .env.example for environment variables"
  else
    echo "Warning: No .env or .env.example file found"
  fi
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

# Set environment variables for FastAPI app
ENV_VARS=""
if [ -f "$ENV_FILE" ]; then
  ENV_VARS="--env-file $ENV_FILE"
fi

# Add essential environment variables
ENV_VARS="$ENV_VARS \
  --env PROJECT_NAME=FastAPI \
  --env POSTGRES_SERVER=localhost \
  --env POSTGRES_USER=postgres \
  --env FIRST_SUPERUSER=admin@example.com \
  --env FIRST_SUPERUSER_PASSWORD=password"

echo "Testing workflow: $1 with event: $EVENT_TYPE"
echo "=================================================="

# Run the workflow with act
echo "Running: act $EVENT_TYPE -W .github/workflows/$(basename "$1") $PLATFORM_FLAGS $ENV_VARS --verbose"
act $EVENT_TYPE -W ".github/workflows/$(basename "$1")" $PLATFORM_FLAGS $ENV_VARS --container-options '--privileged' --verbose || {
  echo "Error: act command failed or timed out"
  echo "You can try:"
  echo "1. Running with specific jobs: act $EVENT_TYPE -W .github/workflows/$(basename "$1") -j <job_id>"
  echo "2. Running with --privileged flag if Docker permissions are needed"
  echo "3. Check if all required secrets are set in .secrets file"
  echo "4. Check if all required dependencies are installed"
  echo "5. Try using Makefile: make test-workflow-params event=$EVENT_TYPE workflow=$(basename "$1")"
  exit 1
}

echo "=================================================="
echo "Workflow test complete"
