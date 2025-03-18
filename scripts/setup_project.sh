#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to create directory if it doesn't exist
create_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo -e "${BLUE}Created directory:${NC} $1"
  fi
}

# Function to create file if it doesn't exist
create_file() {
  if [ ! -f "$1" ]; then
    touch "$1"
    echo -e "${BLUE}Created file:${NC} $1"
  fi
}

echo -e "${GREEN}Setting up project structure...${NC}"

# Create main directories
create_dir "backend"
create_dir "frontend"
create_dir "scripts"
create_dir "docs"
create_dir "make"
create_dir "reports"

# Create backend structure
create_dir "backend/app"
create_dir "backend/app/api"
create_dir "backend/app/core"
create_dir "backend/app/db"
create_dir "backend/app/models"
create_dir "backend/app/schemas"
create_dir "backend/app/services"
create_dir "backend/app/tests"
create_dir "backend/docs"

# Create frontend structure
create_dir "frontend/src"
create_dir "frontend/src/components"
create_dir "frontend/src/pages"
create_dir "frontend/src/styles"
create_dir "frontend/src/utils"
create_dir "frontend/public"
create_dir "frontend/tests"
create_dir "frontend/docs"

# Create documentation directories
create_dir "docs/api"
create_dir "docs/frontend"
create_dir "docs/backend"
create_dir "docs/architecture"
create_dir "docs/development"
create_dir "docs/deployment"

# Create report directories
create_dir "reports/security"
create_dir "reports/tests"
create_dir "reports/accessibility"
create_dir "reports/coverage"

# Create necessary files
create_file "backend/requirements.txt"
create_file "frontend/package.json"
create_file "frontend/pnpm-lock.yaml"
create_file ".env"
create_file ".env.test"
create_file ".gitignore"
create_file "README.md"

echo -e "${GREEN}Project structure setup complete!${NC}"
