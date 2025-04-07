#!/usr/bin/env bash
#
# ===================================================================
# CI/CD WORKFLOW TESTER
# ===================================================================
#
# PURPOSE:
#   Tests the complete CI/CD workflow pipeline using GitHub Actions
#   local runner (act). Validates that all workflow steps are working
#   correctly before pushing to the repository.
#
# USAGE:
#   ./scripts/ci/test-ci-workflow.sh [--verbose] [--secret-file FILE]
#
# OPTIONS:
#   --verbose      Show detailed output from workflow runs
#   --secret-file  Path to a file containing secrets for the workflow
#
# DEPENDENCIES:
#   - act (GitHub Actions local runner)
#   - Docker
#
# ===================================================================

# Exit in case of error
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

# Check if act is installed
if ! command -v act &> /dev/null; then
  echo -e "${RED}Error: 'act' is not installed${NC}"
  echo -e "${YELLOW}Please install it with: brew install act${NC}"
  exit 1
fi

# Load secrets if provided
if [ -n "$SECRET_FILE" ]; then
  if [ -f "$SECRET_FILE" ]; then
    echo -e "${BLUE}Loading secrets from $SECRET_FILE${NC}"
    # shellcheck disable=SC1090
    source "$SECRET_FILE"
  else
    echo -e "${RED}Error: Secret file $SECRET_FILE not found${NC}"
    exit 1
  fi
fi

# CI/CD workflow files to test
CI_CD_WORKFLOWS=(
  "feature-branch-pr.yml:push"
  "pr-checks.yml:pull_request"
  "merge-to-staging.yml:pull_request"
  "merge-to-main.yml:pull_request"
)

# Print header
echo -e "${BLUE}=== Testing CI/CD Workflow ===${NC}"
echo -e "${YELLOW}This will test all components of the CI/CD pipeline:${NC}"
echo -e "  ${GREEN}1. Feature branch -> Auto PR to staging${NC}"
echo -e "  ${GREEN}2. PR checks (tests, lint, format, security)${NC}"
echo -e "  ${GREEN}3. Merge to staging -> Build and tag images${NC}"
echo -e "  ${GREEN}4. Auto PR from staging to main${NC}"
echo -e "  ${GREEN}5. Merge to main -> Retag images with semantic versioning${NC}"
echo ""

# Test each workflow in the CI/CD pipeline
FAILED=0
for workflow_event in "${CI_CD_WORKFLOWS[@]}"; do
  IFS=: read -r workflow event <<< "$workflow_event"
  echo -e "${BLUE}Testing workflow: ${GREEN}$workflow${NC} with event: ${GREEN}$event${NC}"

  # Use the existing test-workflow.sh script
  if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Running command: ./scripts/test/test-workflow.sh .github/workflows/$workflow $event${NC}"
    ./scripts/test/test-workflow.sh .github/workflows/$workflow $event
  else
    ./scripts/test/test-workflow.sh .github/workflows/$workflow $event > /dev/null 2>&1
  fi

  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Workflow $workflow failed with event $event${NC}"
    FAILED=1
  else
    echo -e "${GREEN}✓ Workflow $workflow passed with event $event${NC}"
  fi
  echo ""
done

# Print summary
if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}=== All CI/CD workflows passed! ===${NC}"
  exit 0
else
  echo -e "${RED}=== Some CI/CD workflows failed! ===${NC}"
  exit 1
fi
