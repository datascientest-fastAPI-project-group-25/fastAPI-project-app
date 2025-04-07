#!/usr/bin/env bash
#
# ===================================================================
# DEPLOYMENT SCRIPT
# ===================================================================
#
# PURPOSE:
#   Unified script for building, pushing, and deploying the application.
#   Combines functionality from build.sh, build-push.sh, and deploy.sh.
#
# USAGE:
#   ./scripts/deploy-app.sh [build|push|deploy|all]
#
#   Options:
#     build   - Build Docker images only
#     push    - Build and push Docker images
#     deploy  - Deploy application to Docker Swarm
#     all     - Build, push, and deploy (default if no option provided)
#
# REQUIRED ENVIRONMENT VARIABLES:
#   - TAG: Docker image tag (required for all operations)
#   - DOMAIN: Domain name (required for deploy operation)
#   - STACK_NAME: Docker stack name (required for deploy operation)
#   - FRONTEND_ENV: Frontend environment (defaults to 'production')
#
# DEPENDENCIES:
#   - Docker
#   - Docker Compose
#   - docker-auto-labels (for deploy operation)
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

# Function to check required environment variables
check_env_vars() {
  local operation=$1
  local missing_vars=0

  if [ -z "${TAG}" ]; then
    echo -e "${RED}Error: TAG environment variable is not set${NC}"
    missing_vars=1
  fi

  if [[ "$operation" == "deploy" || "$operation" == "all" ]]; then
    if [ -z "${DOMAIN}" ]; then
      echo -e "${RED}Error: DOMAIN environment variable is not set${NC}"
      missing_vars=1
    fi

    if [ -z "${STACK_NAME}" ]; then
      echo -e "${RED}Error: STACK_NAME environment variable is not set${NC}"
      missing_vars=1
    fi
  fi

  # Set default for FRONTEND_ENV if not provided
  FRONTEND_ENV=${FRONTEND_ENV:-production}

  if [ $missing_vars -eq 1 ]; then
    exit 1
  fi

  echo -e "${GREEN}✓ All required environment variables are set${NC}"
}

# Function to build Docker images
build_images() {
  echo -e "${BLUE}Building Docker images with tag: ${TAG}${NC}"

  docker compose \
    -f docker-compose.yml \
    build

  echo -e "${GREEN}✓ Docker images built successfully${NC}"
}

# Function to push Docker images
push_images() {
  echo -e "${BLUE}Pushing Docker images with tag: ${TAG}${NC}"

  docker compose -f docker-compose.yml push

  echo -e "${GREEN}✓ Docker images pushed successfully${NC}"
}

# Function to deploy the application
deploy_app() {
  echo -e "${BLUE}Deploying application to stack: ${STACK_NAME}${NC}"

  # Check if docker-auto-labels is available
  if ! command -v docker-auto-labels &> /dev/null; then
    echo -e "${YELLOW}Warning: docker-auto-labels is not installed${NC}"
    echo "Continuing without auto-labels..."
  else
    echo -e "${BLUE}Generating Docker stack configuration with auto-labels${NC}"
    docker-auto-labels docker-stack.yml
  fi

  # Generate stack configuration
  docker compose \
    -f docker-compose.yml \
    config > docker-stack.yml

  # Deploy the stack
  docker stack deploy -c docker-stack.yml --with-registry-auth "${STACK_NAME}"

  echo -e "${GREEN}✓ Application deployed successfully${NC}"
}

# Main execution
main() {
  local operation=${1:-all}

  echo -e "${BLUE}=== DevOps Demo Application - Deployment Script ===${NC}"

  # Check Docker availability
  check_docker

  # Check environment variables
  check_env_vars "$operation"

  # Perform the requested operation
  case "$operation" in
    build)
      build_images
      ;;
    push)
      build_images
      push_images
      ;;
    deploy)
      deploy_app
      ;;
    all)
      build_images
      push_images
      deploy_app
      ;;
    *)
      echo -e "${RED}Error: Invalid operation: $operation${NC}"
      echo "Usage: $0 [build|push|deploy|all]"
      exit 1
      ;;
  esac

  echo -e "${GREEN}=== Operation completed successfully ===${NC}"
}

# Execute main function
main "$@"
