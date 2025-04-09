#!/bin/bash
# Script to test Docker builds locally

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Default values
COMPONENT=""
ENVIRONMENT="stg"
VERSION="0.1.0"
GIT_HASH=$(git rev-parse --short HEAD)

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --component)
      COMPONENT="$2"
      shift 2
      ;;
    --env)
      ENVIRONMENT="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      exit 1
      ;;
  esac
done

# Validate component
if [[ "$COMPONENT" != "backend" && "$COMPONENT" != "frontend" && "$COMPONENT" != "all" ]]; then
  echo -e "${RED}Error: --component must be 'backend', 'frontend', or 'all'${NC}"
  echo "Usage: $0 --component [backend|frontend|all] [--env stg|prod] [--version X.Y.Z]"
  exit 1
fi

# Project root directory
PROJECT_ROOT=$(git rev-parse --show-toplevel)
if [ -z "$PROJECT_ROOT" ]; then
  PROJECT_ROOT=$(pwd)
fi

echo -e "${GREEN}=== Docker Build Test ===${NC}"
echo "Component: $COMPONENT"
echo "Environment: $ENVIRONMENT"
echo "Version: $VERSION"
echo "Git Hash: $GIT_HASH"
echo "Project Root: $PROJECT_ROOT"
echo ""

# Function to build backend
build_backend() {
  echo -e "${GREEN}Building backend image...${NC}"

  # Debug: Check if uv.lock exists
  echo -e "${YELLOW}Checking for uv.lock file...${NC}"
  if [ -f "$PROJECT_ROOT/backend/uv.lock" ]; then
    echo -e "${GREEN}✓ uv.lock file found in backend directory${NC}"
    ls -la "$PROJECT_ROOT/backend/uv.lock"
  else
    echo -e "${RED}✗ uv.lock file NOT found in backend directory${NC}"
    echo "Listing backend directory contents:"
    ls -la "$PROJECT_ROOT/backend/"
  fi

  # Test with repository root as context (original workflow approach)
  echo -e "${YELLOW}Testing build with repository root context...${NC}"
  docker build \
    --build-arg APP_VERSION="$VERSION" \
    --build-arg GIT_HASH="$GIT_HASH" \
    --build-arg BRANCH_TYPE="$ENVIRONMENT" \
    -t backend-test-root:latest \
    -f "$PROJECT_ROOT/backend/Dockerfile" \
    "$PROJECT_ROOT"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend build with repository root context succeeded${NC}"
  else
    echo -e "${RED}✗ Backend build with repository root context failed${NC}"
  fi

  # Test with backend directory as context (new workflow approach)
  echo -e "${YELLOW}Testing build with backend directory context...${NC}"
  echo "Verifying uv.lock is in the context directory..."
  ls -la "$PROJECT_ROOT/backend/uv.lock" || echo "uv.lock not found!"

  # First, let's try a very simple test to see if we can copy the uv.lock file at all
  echo -e "${YELLOW}Creating a test Dockerfile to debug the copy issue...${NC}"
  cat > "$PROJECT_ROOT/backend/Dockerfile.test" << 'EOF'
FROM python:3.11-slim
WORKDIR /app
COPY uv.lock /app/
RUN ls -la /app/uv.lock
CMD ["echo", "Success!"]
EOF

  echo -e "${YELLOW}Testing with simplified Dockerfile...${NC}"
  docker build -t backend-test-simple:latest -f "$PROJECT_ROOT/backend/Dockerfile.test" "$PROJECT_ROOT/backend"

  echo -e "${YELLOW}Now testing with the actual Dockerfile...${NC}"
  docker build \
    --debug \
    --build-arg APP_VERSION="$VERSION" \
    --build-arg GIT_HASH="$GIT_HASH" \
    --build-arg BRANCH_TYPE="$ENVIRONMENT" \
    -t backend-test-dir:latest \
    -f "$PROJECT_ROOT/backend/Dockerfile" \
    "$PROJECT_ROOT/backend"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Backend build with backend directory context succeeded${NC}"
  else
    echo -e "${RED}✗ Backend build with backend directory context failed${NC}"
  fi
}

# Function to build frontend
build_frontend() {
  echo -e "${GREEN}Building frontend image...${NC}"

  # Test with repository root as context (current workflow approach)
  echo -e "${YELLOW}Testing build with repository root context...${NC}"
  docker build \
    --build-arg APP_VERSION="$VERSION" \
    --build-arg GIT_HASH="$GIT_HASH" \
    --build-arg BRANCH_TYPE="$ENVIRONMENT" \
    -t frontend-test-root:latest \
    -f "$PROJECT_ROOT/frontend/Dockerfile" \
    "$PROJECT_ROOT"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend build with repository root context succeeded${NC}"
  else
    echo -e "${RED}✗ Frontend build with repository root context failed${NC}"
  fi

  # Test with frontend directory as context (new workflow approach)
  echo -e "${YELLOW}Testing build with frontend directory context...${NC}"
  echo "Verifying package.json is in the context directory..."
  ls -la "$PROJECT_ROOT/frontend/package.json" || echo "package.json not found!"

  docker build \
    --build-arg APP_VERSION="$VERSION" \
    --build-arg GIT_HASH="$GIT_HASH" \
    --build-arg BRANCH_TYPE="$ENVIRONMENT" \
    -t frontend-test-dir:latest \
    -f "$PROJECT_ROOT/frontend/Dockerfile" \
    "$PROJECT_ROOT/frontend"

  if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Frontend build with frontend directory context succeeded${NC}"
  else
    echo -e "${RED}✗ Frontend build with frontend directory context failed${NC}"
  fi
}

# Build components based on selection
if [[ "$COMPONENT" == "backend" || "$COMPONENT" == "all" ]]; then
  build_backend
fi

if [[ "$COMPONENT" == "frontend" || "$COMPONENT" == "all" ]]; then
  build_frontend
fi

echo -e "${GREEN}=== Docker Build Test Complete ===${NC}"
