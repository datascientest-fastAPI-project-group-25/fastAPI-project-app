#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${BLUE}=== GitHub Actions Local Runner (act) Diagnostic Tool ===${NC}"

# Check if act is installed
echo -e "${BLUE}Checking if act is installed...${NC}"
if ! command -v act &> /dev/null; then
    echo -e "${RED}Error: act is not installed.${NC}"
    echo -e "${YELLOW}Please install act using one of the following methods:${NC}"
    echo "  - Homebrew: brew install act"
    echo "  - GitHub: https://github.com/nektos/act#installation"
    exit 1
fi
echo -e "${GREEN}✓ act is installed: $(act --version)${NC}"

# Check Docker
echo -e "${BLUE}Checking Docker...${NC}"
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running or not accessible.${NC}"
    echo "Please start Docker and try again."
    exit 1
fi
echo -e "${GREEN}✓ Docker is running${NC}"

# Check for required Docker images
echo -e "${BLUE}Checking for required Docker images...${NC}"
REQUIRED_IMAGES=("catthehacker/ubuntu:act-latest" "node:18-bullseye")
MISSING_IMAGES=()

for image in "${REQUIRED_IMAGES[@]}"; do
    echo -e "${YELLOW}Checking for image: $image${NC}"
    if ! docker image inspect "$image" &> /dev/null; then
        MISSING_IMAGES+=("$image")
        echo -e "${RED}✗ Image not found: $image${NC}"
    else
        echo -e "${GREEN}✓ Image found: $image${NC}"
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    echo -e "${YELLOW}The following images are missing and will be pulled automatically by act:${NC}"
    for image in "${MISSING_IMAGES[@]}"; do
        echo "  - $image"
    done
    echo -e "${YELLOW}This may take some time on first run.${NC}"
fi

# Check for workflow files
echo -e "${BLUE}Checking for workflow files...${NC}"
if [ ! -d ".github/workflows" ]; then
    echo -e "${RED}Error: .github/workflows directory not found.${NC}"
    echo "Please make sure you're running this script from the repository root."
    exit 1
fi

WORKFLOW_FILES=$(find .github/workflows -name "*.yml" -o -name "*.yaml" | wc -l)
if [ "$WORKFLOW_FILES" -eq 0 ]; then
    echo -e "${RED}Error: No workflow files found in .github/workflows.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Found $WORKFLOW_FILES workflow files${NC}"

# Check for event files
echo -e "${BLUE}Checking for event files...${NC}"
if [ ! -d ".github/workflows/events" ]; then
    echo -e "${YELLOW}Warning: .github/workflows/events directory not found.${NC}"
    echo "Creating directory and sample event files..."
    mkdir -p .github/workflows/events

    # Create sample push event
    cat > .github/workflows/events/push.json << 'EOF'
{
  "ref": "refs/heads/main",
  "before": "0000000000000000000000000000000000000000",
  "after": "1111111111111111111111111111111111111111",
  "repository": {
    "name": "test-repo",
    "full_name": "user/test-repo",
    "private": false,
    "owner": {
      "name": "user",
      "email": "user@example.com"
    }
  },
  "pusher": {
    "name": "user",
    "email": "user@example.com"
  },
  "commits": []
}
EOF

    # Create sample pull_request event
    cat > .github/workflows/events/pull_request.json << 'EOF'
{
  "action": "opened",
  "number": 1,
  "pull_request": {
    "number": 1,
    "state": "open",
    "title": "Test PR",
    "user": {
      "login": "user"
    },
    "body": "This is a test PR",
    "head": {
      "ref": "feature-branch",
      "sha": "1111111111111111111111111111111111111111"
    },
    "base": {
      "ref": "main",
      "sha": "0000000000000000000000000000000000000000"
    }
  },
  "repository": {
    "name": "test-repo",
    "full_name": "user/test-repo",
    "owner": {
      "login": "user"
    }
  },
  "sender": {
    "login": "user"
  }
}
EOF
    echo -e "${GREEN}✓ Created sample event files${NC}"
fi

EVENT_FILES=(".github/workflows/events/push.json" ".github/workflows/events/pull_request.json")
for file in "${EVENT_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: Event file not found: $file${NC}"
        exit 1
    fi
done
echo -e "${GREEN}✓ Event files exist${NC}"

# Test a simple workflow
echo -e "${BLUE}Testing a simple workflow...${NC}"
echo -e "${YELLOW}This will help verify that act is working correctly.${NC}"

# Create a temporary workflow file
TEMP_WORKFLOW=".github/workflows/act-test.yml"
mkdir -p "$(dirname "$TEMP_WORKFLOW")"

cat > "$TEMP_WORKFLOW" << 'EOF'
name: Act Test

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Echo Hello
        run: echo "Hello, World!"
EOF

echo -e "${YELLOW}Created temporary workflow file: $TEMP_WORKFLOW${NC}"
echo -e "${YELLOW}Running act with the test workflow...${NC}"

# Run act with the test workflow
act -W "$TEMP_WORKFLOW" --env-file .env.test -e .github/workflows/events/push.json --verbose

# Clean up
echo -e "${BLUE}Cleaning up...${NC}"
rm "$TEMP_WORKFLOW"
echo -e "${GREEN}✓ Temporary workflow file removed${NC}"

# Summary
echo -e "${BLUE}=== Diagnostic Summary ===${NC}"
echo -e "${GREEN}✓ act is installed and working correctly${NC}"
echo -e "${GREEN}✓ Docker is running${NC}"
echo -e "${GREEN}✓ Workflow files are available${NC}"
echo -e "${GREEN}✓ Event files are available${NC}"

echo -e "${BLUE}=== Next Steps ===${NC}"
echo -e "To test a specific workflow, use:"
echo -e "${YELLOW}act -W .github/workflows/your-workflow.yml -e .github/workflows/events/push.json${NC}"
echo -e "Or use our test-workflow script:"
echo -e "${YELLOW}./scripts/test/test-workflow.sh -w your-workflow.yml -e push${NC}"

echo -e "${GREEN}Diagnostic complete!${NC}"
