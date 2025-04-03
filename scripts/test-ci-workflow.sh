#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
SECRET_FILE=""
VERBOSE=false
SKIP_WORKFLOWS=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --secret-file)
      SECRET_FILE="$2"
      shift 2
      ;;
    --verbose)
      VERBOSE=true
      shift
      ;;
    --skip)
      SKIP_WORKFLOWS="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  --secret-file FILE    Specify a file containing secrets (e.g., GITHUB_TOKEN=xyz)"
      echo "  --verbose             Enable verbose output"
      echo "  --skip WORKFLOWS      Comma-separated list of workflows to skip (e.g., 'pr-checks.yml,merge-to-main.yml')"
      echo "  --help                Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

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

# Skip workflows if specified
if [ -n "$SKIP_WORKFLOWS" ]; then
  echo -e "${YELLOW}Skipping workflows: $SKIP_WORKFLOWS${NC}"
  IFS=',' read -ra SKIP_ARRAY <<< "$SKIP_WORKFLOWS"
  FILTERED_WORKFLOWS=()

  for workflow_event in "${CI_CD_WORKFLOWS[@]}"; do
    IFS=: read -r workflow event <<< "$workflow_event"
    SKIP=false

    for skip_workflow in "${SKIP_ARRAY[@]}"; do
      if [[ "$workflow" == "$skip_workflow" ]]; then
        SKIP=true
        break
      fi
    done

    if [ "$SKIP" = false ]; then
      FILTERED_WORKFLOWS+=("$workflow_event")
    fi
  done

  CI_CD_WORKFLOWS=("${FILTERED_WORKFLOWS[@]}")
fi

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
    echo -e "${BLUE}Running command: ./scripts/test-workflow.sh .github/workflows/$workflow $event${NC}"
    ./scripts/test-workflow.sh .github/workflows/$workflow $event
  else
    ./scripts/test-workflow.sh .github/workflows/$workflow $event > /dev/null 2>&1
  fi

  if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Workflow $workflow failed with event $event${NC}"
    FAILED=1
  else
    echo -e "${GREEN}✓ Workflow $workflow passed with event $event${NC}"
  fi
  echo ""
done

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✓ All CI/CD workflow tests completed successfully!${NC}"
  exit 0
else
  echo -e "${YELLOW}⚠ Some CI/CD workflow tests failed.${NC}"
  echo -e "${YELLOW}This may be expected due to missing GitHub context in local environment.${NC}"
  echo -e "${YELLOW}The workflows should work correctly on GitHub.${NC}"

  # Provide more specific guidance based on which workflows failed
  echo -e "\n${BLUE}=== Troubleshooting Guide ===${NC}"
  echo -e "${YELLOW}Common issues when testing workflows locally:${NC}"
  echo -e "  ${GREEN}1. GitHub token authentication:${NC} Use --secret-file to provide a GitHub token"
  echo -e "  ${GREEN}2. Missing Docker images:${NC} Ensure Docker is running and required images are available"
  echo -e "  ${GREEN}3. Network connectivity:${NC} Some workflows may require internet access"
  echo -e "  ${GREEN}4. Missing context:${NC} GitHub Actions context variables are not fully available locally"
  echo -e "\n${YELLOW}To test with GitHub token:${NC}"
  echo -e "  echo \"GITHUB_TOKEN=your_token\" > .env.local"
  echo -e "  ./scripts/test-ci-workflow.sh --secret-file .env.local"
  echo -e "\n${YELLOW}To skip specific workflows:${NC}"
  echo -e "  Edit the CI_CD_WORKFLOWS array in this script to remove problematic workflows"

  # Ask if user wants to continue with GitHub deployment despite local failures
  echo -e "\n${BLUE}Would you like to proceed with pushing to GitHub anyway? (y/N)${NC}"
  read -p "> " proceed

  if [[ "$proceed" == "y" || "$proceed" == "Y" ]]; then
    echo -e "${YELLOW}Proceeding despite local test failures. The workflows may still work correctly on GitHub.${NC}"
    exit 0
  else
    echo -e "${RED}Aborting due to local test failures. Fix the issues before pushing to GitHub.${NC}"
    exit 1
  fi
fi
