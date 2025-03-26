#!/bin/bash

# Test a GitHub Actions workflow locally using act
# Usage: ./test-workflow.sh <workflow-file> <event-type> [job-name]
# Example: ./test-workflow.sh feature-branch.yml push
# Example with specific job: ./test-workflow.sh feature-branch.yml push style-checks

set -e

if [ $# -lt 2 ]; then
  echo "Usage: $0 <workflow-file> <event-type> [job-name]"
  echo "Example: $0 feature-branch.yml push"
  echo "Example with specific job: $0 feature-branch.yml push style-checks"
  exit 1
fi

WORKFLOW_FILE="$1"
EVENT_TYPE="$2"
JOB_NAME="$3"

# Check if act is installed
if ! command -v act &> /dev/null; then
  echo "Error: 'act' is not installed. Please install it first."
  echo "See: https://github.com/nektos/act"
  echo "Install with: brew install act"
  exit 1
fi

# Create .actrc file if it doesn't exist
if [ ! -f ".actrc" ]; then
  echo "Creating .actrc file with recommended settings..."
  cat > .actrc << EOL
--container-architecture linux/amd64
--env-file .env
--env CI=true
-P ubuntu-latest=node:18-bullseye
-P ubuntu-22.04=node:18-bullseye
-P ubuntu-20.04=node:16-bullseye
--secret GITHUB_TOKEN=
--secret CR_PAT=
--bind
EOL
  echo ".actrc file created"
fi

# Create test event file if it doesn't exist
if [ ! -f ".github/workflows/utils/test-event.json" ]; then
  echo "Creating test event file..."
  mkdir -p .github/workflows/utils
  cat > .github/workflows/utils/test-event.json << EOL
{
  "ref": "refs/heads/feat/test-feature",
  "repository": {
    "name": "fastAPI-project-app",
    "full_name": "datascientest-fastAPI-project-group-25/fastAPI-project-app",
    "private": true
  },
  "pusher": {
    "name": "$(git config user.name || echo 'test-user')"
  }
}
EOL
  echo "Test event file created"
fi

# Run the workflow
echo "Testing workflow: $WORKFLOW_FILE with event: $EVENT_TYPE"
cd "$(git rev-parse --show-toplevel)"

# Find the workflow file in any of the subdirectories
WORKFLOW_PATH=""
for dir in ".github/workflows" ".github/workflows/branch" ".github/workflows/ci" ".github/workflows/utils"; do
  if [ -f "$dir/$WORKFLOW_FILE" ]; then
    WORKFLOW_PATH="$dir/$WORKFLOW_FILE"
    break
  fi
done

# If workflow not found, default to the original path
if [ -z "$WORKFLOW_PATH" ]; then
  WORKFLOW_PATH=".github/workflows/$WORKFLOW_FILE"
  echo "Warning: Workflow file not found in subdirectories, using default path"
fi

echo "Using workflow path: $WORKFLOW_PATH"
ACT_ARGS="-W $WORKFLOW_PATH -e .github/workflows/utils/test-event.json $EVENT_TYPE"

# If a specific job is specified, add it to the arguments
if [ -n "$JOB_NAME" ]; then
  echo "Running specific job: $JOB_NAME"
  ACT_ARGS="$ACT_ARGS -j $JOB_NAME"
fi

# Run act with the constructed arguments
act $ACT_ARGS
