#!/bin/bash
set -e

WORKFLOW_FILE="$1"
EVENT_TYPE="$2"

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo -e "${RED}Error: Workflow file not found: $WORKFLOW_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Testing workflow: $WORKFLOW_FILE with event: $EVENT_TYPE${NC}"
echo "================================================="

# Use event files
EVENT_FILE=".github/workflows/events/${EVENT_TYPE}.json"
if [ ! -f "$EVENT_FILE" ]; then
    echo -e "${RED}Error: Event file not found: $EVENT_FILE${NC}"
    exit 1
fi
EVENT_ARG="--eventpath=$EVENT_FILE"

# Run the workflow with act
echo -e "${YELLOW}Running: act $EVENT_ARG -W $WORKFLOW_FILE with test environment${NC}"

# Use test environment variables
ENV_FILE=".env.test"
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: Test environment file not found: $ENV_FILE${NC}"
    exit 1
fi

if act $EVENT_ARG -W "$WORKFLOW_FILE" --env-file "$ENV_FILE" --container-architecture linux/amd64 --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest -b; then
    echo -e "\n${GREEN}✓ Workflow test completed successfully!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Workflow test failed!${NC}"
    exit 1
fi
