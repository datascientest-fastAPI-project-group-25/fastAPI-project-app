#!/usr/bin/env bash
#
# ===================================================================
# TESTING SCRIPT
# ===================================================================
#
# PURPOSE:
#   Unified script for running tests locally or in CI environments.
#   Combines functionality from test.sh and test-local.sh.
#
# USAGE:
#   ./scripts/test-app.sh [local|ci] [test_args...]
#
#   Options:
#     local  - Run tests in local development environment (default)
#     ci     - Run tests in CI environment
#
#   Additional arguments are passed to pytest
#   Example: ./scripts/test-app.sh local -xvs app/tests/api/
#
# ENVIRONMENT VARIABLES:
#   - SKIP_CLEANUP: Set to any value to skip cleanup after tests
#   - SKIP_BUILD: Set to any value to skip Docker build step
#
# DEPENDENCIES:
#   - Docker
#   - Docker Compose
#
# ===================================================================

# Exit in case of error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if Docker is available
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not in PATH${NC}"
    echo "Please install Docker and try again"
    exit 1
  fi

  # Check if Docker daemon is running
  if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker daemon is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
  fi

  echo -e "${GREEN}✓ Docker is available${NC}"
}

# Function to clean up previous test environments
cleanup_previous() {
  echo -e "${BLUE}Cleaning up previous test environments...${NC}"

  docker compose down -v --remove-orphans

  echo -e "${GREEN}✓ Previous environments cleaned up${NC}"
}

# Function to clean up Python cache files (Linux only)
cleanup_cache() {
  if [ "$(uname -s)" = "Linux" ]; then
    echo -e "${BLUE}Removing __pycache__ files...${NC}"

    # Use sudo only if necessary
    if [ -w "$(find . -name __pycache__ -type d | head -n 1 2>/dev/null)" ] || [ -z "$(find . -name __pycache__ -type d | head -n 1 2>/dev/null)" ]; then
      find . -type d -name __pycache__ -exec rm -r {} \+ 2>/dev/null || true
    else
      sudo find . -type d -name __pycache__ -exec rm -r {} \+ 2>/dev/null || true
    fi

    echo -e "${GREEN}✓ Cache files removed${NC}"
  fi
}

# Function to build Docker images
build_images() {
  if [ -z "${SKIP_BUILD}" ]; then
    echo -e "${BLUE}Building Docker images...${NC}"

    docker compose build

    echo -e "${GREEN}✓ Docker images built successfully${NC}"
  else
    echo -e "${YELLOW}Skipping build step (SKIP_BUILD is set)${NC}"
    echo -e "${YELLOW}Don't forget to run 'docker compose down -v' when you're done${NC}"
  fi
}

# Function to start Docker services
start_services() {
  echo -e "${BLUE}Starting Docker services...${NC}"

  docker compose up -d

  echo -e "${GREEN}✓ Docker services started${NC}"
}

# Function to run tests
run_tests() {
  local test_args="$*"

  echo -e "${BLUE}Running tests with arguments: ${test_args}${NC}"

  docker compose exec -T backend bash scripts/tests-start.sh "$test_args"

  echo -e "${GREEN}✓ Tests completed${NC}"
}

# Function to clean up after tests
cleanup_after() {
  if [ -z "${SKIP_CLEANUP}" ]; then
    echo -e "${BLUE}Cleaning up after tests...${NC}"

    docker compose down -v --remove-orphans

    echo -e "${GREEN}✓ Test environment cleaned up${NC}"
  else
    echo -e "${YELLOW}Skipping cleanup (SKIP_CLEANUP is set)${NC}"
    echo -e "${YELLOW}Don't forget to run 'docker compose down -v' when you're done${NC}"
  fi
}

# Function to run tests in CI environment
run_ci_tests() {
  local test_args="$*"

  # In CI, we want to build, run tests, and clean up regardless of errors
  build_images

  # Start services
  start_services

  # Run tests
  run_tests $test_args

  # Always clean up in CI
  docker compose down -v --remove-orphans
}

# Function to run tests in local environment
run_local_tests() {
  local test_args="$*"

  # Clean up previous environments
  cleanup_previous

  # Clean up cache files
  cleanup_cache

  # Build images
  build_images

  # Start services
  start_services

  # Run tests
  run_tests $test_args

  # Clean up after tests
  cleanup_after
}

# Main execution
main() {
  local mode=${1:-local}
  shift || true

  echo -e "${BLUE}=== DevOps Demo Application - Testing Script ===${NC}"

  # Check Docker availability
  check_docker

  # Perform the requested operation
  case "$mode" in
    local)
      echo -e "${BLUE}Running tests in local environment${NC}"
      run_local_tests "$@"
      ;;
    ci)
      echo -e "${BLUE}Running tests in CI environment${NC}"
      run_ci_tests "$@"
      ;;
    *)
      echo -e "${RED}Error: Invalid mode: $mode${NC}"
      echo "Usage: $0 [local|ci] [test_args...]"
      exit 1
    ;;
  esac

  echo -e "${GREEN}=== Testing completed successfully ===${NC}"
}

# Execute main function
main "$@"
