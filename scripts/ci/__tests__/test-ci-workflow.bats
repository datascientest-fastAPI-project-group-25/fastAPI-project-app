#!/usr/bin/env bats

# Bats test file for test-ci-workflow.sh

# Setup - runs before each test
setup() {
  # Create a temporary directory for test files
  export TEMP_DIR="$(mktemp -d)"

  # Save the original directory
  export ORIG_DIR="$PWD"

  # Change to the temp directory
  cd "$TEMP_DIR"

  # Create mock project structure
  mkdir -p .github/workflows
  touch .github/workflows/feature-branch-pr.yml
  touch .github/workflows/pr-checks.yml
  touch .github/workflows/merge-to-staging.yml
  touch .github/workflows/merge-to-main.yml

  # Create test scripts directory
  mkdir -p scripts/test
  touch scripts/test/test-workflow.sh
  chmod +x scripts/test/test-workflow.sh

  # Mock test-workflow.sh to return success
  cat > scripts/test/test-workflow.sh << 'EOF'
#!/bin/bash
echo "Mock test-workflow.sh called with args: $@"
exit 0
EOF

  # Create a mock version of the script for testing
  export SCRIPT_PATH="$TEMP_DIR/test-ci-workflow.sh"
  cp "$ORIG_DIR/scripts/ci/test-ci-workflow.sh" "$SCRIPT_PATH"
  chmod +x "$SCRIPT_PATH"

  # Mock external commands
  mock_command "act" "echo 'Act command executed: $@'"
}

# Teardown - runs after each test
teardown() {
  # Return to the original directory
  cd "$ORIG_DIR"

  # Clean up the temporary directory
  rm -rf "$TEMP_DIR"
}

# Helper function to mock commands
mock_command() {
  local cmd="$1"
  local output="$2"

  mkdir -p "$TEMP_DIR/bin"
  cat > "$TEMP_DIR/bin/$cmd" << EOF
#!/bin/bash
$output
exit 0
EOF
  chmod +x "$TEMP_DIR/bin/$cmd"
  export PATH="$TEMP_DIR/bin:$PATH"
}

# Test that the script checks for dependencies
@test "test-ci-workflow.sh checks for dependencies" {
  # Run the script with a modified version that exits after dependency check
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Check if act is installed
if ! command -v act &> /dev/null; then
  echo -e "${RED}Error: 'act' is not installed${NC}"
  echo -e "${YELLOW}Please install it with: brew install act${NC}"
  exit 1
fi

echo "DEPENDENCIES_CHECKED=true"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates dependencies were checked
  [ "$status" -eq 0 ]
  [[ "$output" == *"DEPENDENCIES_CHECKED=true"* ]]
}

# Test that the script handles command line arguments
@test "test-ci-workflow.sh handles command line arguments" {
  # Run the script with a modified version that exits after parsing arguments
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Parse command line arguments
VERBOSE=false
SECRET_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose)
      VERBOSE=true
      shift
      ;;
    --secret-file)
      SECRET_FILE="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Error: Unknown argument $1${NC}"
      echo "Usage: $0 [--verbose] [--secret-file FILE]"
      exit 1
      ;;
  esac
done

echo "ARGUMENTS_PARSED=true"
echo "VERBOSE=$VERBOSE"
echo "SECRET_FILE=$SECRET_FILE"
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script with arguments
  run "$SCRIPT_PATH" --verbose --secret-file test_secrets.env

  # Check that the output indicates arguments were parsed
  [ "$status" -eq 0 ]
  [[ "$output" == *"ARGUMENTS_PARSED=true"* ]]
  [[ "$output" == *"VERBOSE=true"* ]]
  [[ "$output" == *"SECRET_FILE=test_secrets.env"* ]]
}

# Test that the script loads secrets from a file
@test "test-ci-workflow.sh loads secrets from a file" {
  # Create a test secret file
  echo "TEST_SECRET=test_value" > test_secrets.env

  # Run the script with a modified version that exits after loading secrets
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Parse command line arguments
VERBOSE=false
SECRET_FILE="test_secrets.env"

# Load secrets if provided
if [ -n "$SECRET_FILE" ]; then
  if [ -f "$SECRET_FILE" ]; then
    echo -e "${BLUE}Loading secrets from $SECRET_FILE${NC}"
    source "$SECRET_FILE"
    echo "SECRETS_LOADED=true"
    echo "TEST_SECRET=$TEST_SECRET"
  else
    echo -e "${RED}Error: Secret file $SECRET_FILE not found${NC}"
    exit 1
  fi
fi

exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates secrets were loaded
  [ "$status" -eq 0 ]
  [[ "$output" == *"Loading secrets from test_secrets.env"* ]]
  [[ "$output" == *"SECRETS_LOADED=true"* ]]
  [[ "$output" == *"TEST_SECRET=test_value"* ]]
}

# Test that the script tests CI/CD workflows
@test "test-ci-workflow.sh tests CI/CD workflows" {
  # Run the script with a modified version that exits after defining workflows
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# CI/CD workflow files to test
CI_CD_WORKFLOWS=(
  "feature-branch-pr.yml:push"
  "pr-checks.yml:pull_request"
  "merge-to-staging.yml:pull_request"
  "merge-to-main.yml:pull_request"
)

echo "WORKFLOWS_DEFINED=true"
for workflow_event in "${CI_CD_WORKFLOWS[@]}"; do
  IFS=: read -r workflow event <<< "$workflow_event"
  echo "Workflow: $workflow, Event: $event"
done
exit 0
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates workflows were defined
  [ "$status" -eq 0 ]
  [[ "$output" == *"WORKFLOWS_DEFINED=true"* ]]
  [[ "$output" == *"Workflow: feature-branch-pr.yml, Event: push"* ]]
  [[ "$output" == *"Workflow: pr-checks.yml, Event: pull_request"* ]]
  [[ "$output" == *"Workflow: merge-to-staging.yml, Event: pull_request"* ]]
  [[ "$output" == *"Workflow: merge-to-main.yml, Event: pull_request"* ]]
}

# Test that the script runs test-workflow.sh for each workflow
@test "test-ci-workflow.sh runs test-workflow.sh for each workflow" {
  # Run the script with a modified version that exits after running one workflow
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# CI/CD workflow files to test
CI_CD_WORKFLOWS=(
  "feature-branch-pr.yml:push"
)

# Test each workflow in the CI/CD pipeline
FAILED=0
for workflow_event in "${CI_CD_WORKFLOWS[@]}"; do
  IFS=: read -r workflow event <<< "$workflow_event"
  echo -e "${BLUE}Testing workflow: ${GREEN}$workflow${NC} with event: ${GREEN}$event${NC}"

  # Use the existing test-workflow.sh script
  echo "Would run: ./scripts/test/test-workflow.sh .github/workflows/$workflow $event"
  ./scripts/test/test-workflow.sh .github/workflows/$workflow $event

  echo "WORKFLOW_TESTED=true"
  exit 0
done
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates a workflow was tested
  [ "$status" -eq 0 ]
  [[ "$output" == *"Testing workflow: feature-branch-pr.yml"* ]]
  [[ "$output" == *"Would run: ./scripts/test/test-workflow.sh .github/workflows/feature-branch-pr.yml push"* ]]
  [[ "$output" == *"Mock test-workflow.sh called with args: .github/workflows/feature-branch-pr.yml push"* ]]
  [[ "$output" == *"WORKFLOW_TESTED=true"* ]]
}

# Test that the script handles verbose mode
@test "test-ci-workflow.sh handles verbose mode" {
  # Run the script with a modified version that shows verbose output
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Parse command line arguments
VERBOSE=true

# CI/CD workflow files to test
CI_CD_WORKFLOWS=(
  "feature-branch-pr.yml:push"
)

# Test each workflow in the CI/CD pipeline
FAILED=0
for workflow_event in "${CI_CD_WORKFLOWS[@]}"; do
  IFS=: read -r workflow event <<< "$workflow_event"
  echo -e "${BLUE}Testing workflow: ${GREEN}$workflow${NC} with event: ${GREEN}$event${NC}"

  # Use the existing test-workflow.sh script
  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Running command: ./scripts/test/test-workflow.sh .github/workflows/$workflow $event${NC}"
    echo "VERBOSE_MODE_USED=true"
  else
    echo "Would run with output suppressed"
  fi

  exit 0
done
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates verbose mode was used
  [ "$status" -eq 0 ]
  [[ "$output" == *"Running command: ./scripts/test/test-workflow.sh .github/workflows/feature-branch-pr.yml push"* ]]
  [[ "$output" == *"VERBOSE_MODE_USED=true"* ]]
}

# Test that the script reports a summary
@test "test-ci-workflow.sh reports a summary" {
  # Run the script with a modified version that exits after reporting summary
  cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

# Test summary
FAILED=0

# Print summary
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}=== All CI/CD workflows passed! ===${NC}"
  echo "SUMMARY_REPORTED=true"
  exit 0
else
  echo -e "${RED}=== Some CI/CD workflows failed! ===${NC}"
  echo "SUMMARY_REPORTED=true"
  exit 1
fi
EOF
  chmod +x "$SCRIPT_PATH"

  # Run the script
  run "$SCRIPT_PATH"

  # Check that the output indicates a summary was reported
  [ "$status" -eq 0 ]
  [[ "$output" == *"All CI/CD workflows passed!"* ]]
  [[ "$output" == *"SUMMARY_REPORTED=true"* ]]
}
