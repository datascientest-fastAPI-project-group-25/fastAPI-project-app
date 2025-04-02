#!/bin/bash
set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}=== ACT Diagnostic Tool ===${NC}"
echo -e "${YELLOW}This script will help diagnose issues with act workflow testing${NC}"
echo "================================================="

# Check if act is installed
echo -e "${BLUE}Checking if act is installed...${NC}"
if ! command -v act &> /dev/null; then
    echo -e "${RED}Error: act is not installed. Please install it first.${NC}"
    echo "You can install it with: brew install act"
    exit 1
fi
echo -e "${GREEN}✓ act is installed${NC}"

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
    echo -e "${YELLOW}Some required Docker images are missing. Would you like to pull them now? (y/n)${NC}"
    read -r pull_images
    if [[ "$pull_images" == "y" ]]; then
        for image in "${MISSING_IMAGES[@]}"; do
            echo -e "${BLUE}Pulling image: $image${NC}"
            docker pull "$image"
        done
    else
        echo -e "${YELLOW}Skipping image pull. Some workflows may fail without these images.${NC}"
    fi
fi

# Check .actrc file
echo -e "${BLUE}Checking .actrc configuration...${NC}"
if [ ! -f ".actrc" ]; then
    echo -e "${RED}Error: .actrc file not found.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ .actrc file exists${NC}"

# Check test environment file
echo -e "${BLUE}Checking test environment file...${NC}"
if [ ! -f ".env.test" ]; then
    echo -e "${RED}Error: .env.test file not found.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ .env.test file exists${NC}"

# Check for event files
echo -e "${BLUE}Checking event files...${NC}"
if [ ! -d ".github/workflows/events" ]; then
    echo -e "${RED}Error: Event files directory not found.${NC}"
    exit 1
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

echo -e "${GREEN}Diagnostic test complete!${NC}"
echo -e "${YELLOW}If the test workflow ran successfully, act is working correctly.${NC}"
echo -e "${YELLOW}If you're still experiencing issues with specific workflows, check:${NC}"
echo "1. The workflow file for syntax errors"
echo "2. Required secrets or environment variables"
echo "3. Docker image compatibility with the workflow"
echo "4. Node.js version requirements for the workflow"
