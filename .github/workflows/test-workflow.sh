#!/bin/bash

# Test a GitHub Actions workflow locally using act
# Usage: ./test-workflow.sh <workflow-file> <event-type>
# Example: ./test-workflow.sh branch/feature.yml push

if [ $# -lt 2 ]; then
  echo "Usage: $0 <workflow-file> <event-type>"
  echo "Example: $0 branch/feature.yml push"
  exit 1
fi

WORKFLOW_FILE="$1"
EVENT_TYPE="$2"

# Check if act is installed
if ! command -v act &> /dev/null; then
  echo "Error: 'act' is not installed. Please install it first."
  echo "See: https://github.com/nektos/act"
  exit 1
fi

# Create .actrc file if it doesn't exist
if [ ! -f ".actrc" ]; then
  echo "Creating .actrc file with recommended settings..."
  cat > .actrc << EOL
-P ubuntu-latest=node:18-bullseye
-P ubuntu-22.04=node:18-bullseye
--env CI=true
EOL
  echo ".actrc file created"
fi

# Run the workflow
echo "Testing workflow: $WORKFLOW_FILE with event: $EVENT_TYPE"
cd "$(git rev-parse --show-toplevel)" && act -W .github/workflows/$WORKFLOW_FILE -e .github/workflows/test-event.json $EVENT_TYPE
