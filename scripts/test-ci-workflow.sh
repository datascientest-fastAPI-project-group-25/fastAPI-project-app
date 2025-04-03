#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
  ./scripts/test-workflow.sh .github/workflows/$workflow $event

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
  exit 1
fi
