#!/bin/bash

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Function to print debug information
debug() {
    echo -e "${BLUE}[DEBUG] $1${NC}"
}

# Function to print error information
error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Function to print success information
success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

# Function to print warning information
warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    error "Not in a git repository"
    exit 1
fi

# Change to the project root directory
cd "$(git rev-parse --show-toplevel)" || exit 1

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    error "Python 3 is not installed. Please install Python 3 and try again."
    exit 1
fi

# Check if the backend directory exists
if [ ! -d "backend" ]; then
    error "Backend directory not found. Please run this script from the project root directory."
    exit 1
fi

# Create a virtual environment if it doesn't exist
if [ ! -d "backend/.venv" ]; then
    echo -e "${YELLOW}Creating virtual environment...${NC}"
    cd backend && python3 -m venv .venv
    success "Virtual environment created."
else
    echo -e "${YELLOW}Virtual environment already exists.${NC}"
fi

# Activate the virtual environment
echo -e "${YELLOW}Activating virtual environment...${NC}"
source backend/.venv/bin/activate

# Install dependencies
echo -e "${YELLOW}Installing dependencies...${NC}"
cd backend && pip install -e ".[dev,test]"
success "Dependencies installed."

# Deactivate the virtual environment
deactivate

success "Virtual environment setup complete. You can now run 'make test-fixed' to run the tests."
