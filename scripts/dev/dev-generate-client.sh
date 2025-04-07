#!/usr/bin/env bash
#
# ===================================================================
# API CLIENT GENERATOR
# ===================================================================
#
# PURPOSE:
#   Generates TypeScript client code from OpenAPI specification.
#   Extracts OpenAPI schema from the FastAPI backend and generates
#   frontend client code for API integration.
#
# USAGE:
#   ./scripts/dev/dev-generate-client.sh
#
# ENVIRONMENT VARIABLES:
#   - SKIP_FORMAT: Set to any value to skip code formatting
#
# DEPENDENCIES:
#   - Python 3.11+
#   - Node.js and npm
#   - Biome (for code formatting)
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

# Function to check if Python is available
check_python() {
  if ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python is not installed${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Python is available${NC}"
}

# Function to check if Node.js is available
check_node() {
  if ! command -v node &> /dev/null; then
    echo -e "${RED}Error: Node.js is not installed${NC}"
    exit 1
  fi
  echo -e "${GREEN}✓ Node.js is available${NC}"
}

# Function to check if Biome is available
check_biome() {
  if [ -z "${SKIP_FORMAT}" ] && ! npx --no biome --version &> /dev/null; then
    echo -e "${YELLOW}Warning: Biome is not installed${NC}"
    echo "Code formatting will be skipped"
    SKIP_FORMAT=1
  else
    echo -e "${GREEN}✓ Biome is available for code formatting${NC}"
  fi
}

# Function to generate OpenAPI schema
generate_schema() {
  echo -e "${BLUE}Generating OpenAPI schema from backend...${NC}"

  cd backend
  python -c "import app.main; import json; print(json.dumps(app.main.app.openapi()))" > ../openapi.json
  cd ..

  if [ -f "openapi.json" ]; then
    echo -e "${GREEN}✓ OpenAPI schema generated successfully${NC}"
    mv openapi.json frontend/
  else
    echo -e "${RED}Error: Failed to generate OpenAPI schema${NC}"
    exit 1
  fi
}

# Function to generate TypeScript client
generate_client() {
  echo -e "${BLUE}Generating TypeScript client in frontend...${NC}"

  cd frontend
  npm run generate-client

  if [ -d "./src/client" ]; then
    echo -e "${GREEN}✓ TypeScript client generated successfully${NC}"
  else
    echo -e "${RED}Error: Failed to generate TypeScript client${NC}"
    exit 1
  fi
}

# Function to format generated code
format_code() {
  if [ -z "${SKIP_FORMAT}" ]; then
    echo -e "${BLUE}Formatting generated client code...${NC}"

    cd frontend
    npx biome format --write ./src/client

    echo -e "${GREEN}✓ Client code formatted successfully${NC}"
  else
    echo -e "${YELLOW}Skipping code formatting (SKIP_FORMAT is set)${NC}"
  fi
}

# Main execution
main() {
  echo -e "${BLUE}=== DevOps Demo Application - API Client Generator ===${NC}"

  # Check dependencies
  check_python
  check_node
  check_biome

  # Generate OpenAPI schema
  generate_schema

  # Generate TypeScript client
  generate_client

  # Format generated code
  format_code

  echo -e "${GREEN}=== API client generation completed successfully ===${NC}"
}

# Execute main function
main
