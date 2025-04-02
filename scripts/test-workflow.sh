#!/bin/bash

# Don't exit on error so we can handle errors gracefully
set +e

WORKFLOW_FILE="$1"
EVENT_TYPE="$2"
EVENT_DATA="$3"
TIMEOUT="${4:-300}"  # Default timeout is 300 seconds (5 minutes)

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Function to print debug information
debug() {
    echo -e "${BLUE}[DEBUG] $1${NC}"
}

# Function to print error information
error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to print success information
success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Function to print warning information
warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if act is installed
if ! command -v act &> /dev/null; then
    error "act is not installed. Please install it with: brew install act"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    error "Docker is not running or not accessible. Please start Docker and try again."
    exit 1
fi

# Check if workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    error "Workflow file not found: $WORKFLOW_FILE"
    exit 1
fi

echo -e "${YELLOW}Testing workflow: $WORKFLOW_FILE with event: $EVENT_TYPE${NC}"
echo "=================================================="

# Use event files
EVENT_FILE=".github/workflows/events/${EVENT_TYPE}.json"
if [ ! -f "$EVENT_FILE" ]; then
    error "Event file not found: $EVENT_FILE"
    exit 1
fi
EVENT_ARG="--eventpath=$EVENT_FILE"

# Use test environment variables
ENV_FILE=".env.test"
if [ ! -f "$ENV_FILE" ]; then
    error "Test environment file not found: $ENV_FILE"
    exit 1
fi

# Check if we're running the local-test.yml workflow
if [[ "$WORKFLOW_FILE" == *"local-test.yml"* ]]; then
    echo -e "${YELLOW}Running simplified local test workflow...${NC}"
    ACT_CMD="act $EVENT_ARG -W \"$WORKFLOW_FILE\" --env ACT=true --env-file \"$ENV_FILE\" --bind"
    TIMEOUT=30
else
    # For regular workflows, set the ACT environment variable to true
    ACT_CMD="act $EVENT_ARG -W \"$WORKFLOW_FILE\" --env ACT=true --env-file \"$ENV_FILE\" --bind"
    TIMEOUT=300
fi

# Add event data if provided
if [ -n "$EVENT_DATA" ]; then
    # Create a temporary event file with the provided data
    TMP_EVENT_FILE="/tmp/act_event_$$.json"
    echo "$EVENT_DATA" > "$TMP_EVENT_FILE"
    ACT_CMD="$ACT_CMD --eventpath=$TMP_EVENT_FILE"
    debug "Using temporary event file with content: $EVENT_DATA"
fi

echo -e "${YELLOW}Running with a ${TIMEOUT}-second timeout...${NC}"
echo -e "${BLUE}Command: $ACT_CMD${NC}"

eval "timeout $TIMEOUT $ACT_CMD" > >(tee act_output.log) 2>&1
ACT_EXIT_CODE=$?

# Check if the command timed out
if [ $ACT_EXIT_CODE -eq 124 ]; then
    echo -e "\n${RED}✗ Workflow test timed out after $TIMEOUT seconds!${NC}"
    echo -e "${YELLOW}This may indicate a hanging process or infinite loop in the workflow.${NC}"
    echo -e "${YELLOW}Try running with different Docker images or flags.${NC}"
    exit 1
fi

# Print the output for debugging
echo -e "${YELLOW}Output from act:${NC}"
cat act_output.log

# Check for specific error patterns in the output regardless of exit code
if grep -q "OCI runtime exec failed\|exitcode '127'\|command not found\|❌.*Failure" act_output.log; then
    echo -e "\n${RED}✗ Workflow test failed with errors:${NC}"
    grep -E "OCI runtime exec failed|exitcode '127'|command not found|❌.*Failure" act_output.log | sed 's/^/    /'
    exit 1
fi

# Check if the output contains any actual job execution
if ! grep -q "Job\|Step\|Run" act_output.log; then
    echo -e "\n${RED}✗ Workflow test did not execute any jobs or steps!${NC}"
    echo -e "${YELLOW}This may indicate that the workflow is misconfigured or act is not working properly.${NC}"
    echo -e "${YELLOW}Try running with different Docker images or flags.${NC}"
    exit 1
fi

# Check for common act issues
if grep -q "hashFiles\|github context\|matrix context" act_output.log; then
    echo -e "\n${YELLOW}⚠️ Warning: The workflow uses GitHub context functions that may not work properly with act.${NC}"
    echo -e "${YELLOW}This includes hashFiles(), github context variables, and matrix context.${NC}"
    echo -e "${YELLOW}Consider simplifying the workflow for local testing.${NC}"
fi

# Check the exit code from act
if [ $ACT_EXIT_CODE -eq 0 ]; then
    # Even if act reports success, check for any failure indicators in the output
    if grep -q "Failure" act_output.log; then
        echo -e "\n${RED}✗ Workflow reported success but contained failures:${NC}"
        grep "Failure" act_output.log | sed 's/^/    /'
        exit 1
    else
        echo -e "\n${GREEN}✓ Workflow test completed successfully!${NC}"
        exit 0
    fi
else
    echo -e "\n${RED}✗ Workflow test failed with exit code $ACT_EXIT_CODE!${NC}"
    exit 1
fi
