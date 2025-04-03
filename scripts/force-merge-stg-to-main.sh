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

# Save current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
debug "Current branch: $CURRENT_BRANCH"

# Step 1: Fetch the latest changes from stg
echo -e "${YELLOW}Step 1: Fetching latest changes from stg${NC}"
if ! git fetch origin stg; then
    error "Failed to fetch latest changes from stg"
    exit 1
fi
success "Fetched latest changes from stg"

# Step 2: Checkout main branch
echo -e "${YELLOW}Step 2: Checking out main branch${NC}"
if ! git checkout main; then
    error "Failed to checkout main branch"
    exit 1
fi
success "Checked out main branch"

# Step 3: Reset main to match stg
echo -e "${YELLOW}Step 3: Resetting main to match stg${NC}"
if ! git reset --hard origin/stg; then
    error "Failed to reset main to match stg"
    git checkout "$CURRENT_BRANCH"
    exit 1
fi
success "Reset main to match stg"

# Step 4: Force push main (bypassing pre-commit hooks)
echo -e "${YELLOW}Step 4: Force pushing main (bypassing pre-commit hooks)${NC}"
if ! git push -f --no-verify origin main; then
    error "Failed to force push main"
    git checkout "$CURRENT_BRANCH"
    exit 1
fi
success "Force pushed main"

# Step 5: Clean up branches
echo -e "${YELLOW}Step 5: Cleaning up branches${NC}"
# Get all branches except main and stg
BRANCHES_TO_DELETE=$(git branch | grep -v "main" | grep -v "stg" | grep -v "\*" | tr -d ' ')

if [ -z "$BRANCHES_TO_DELETE" ]; then
    warning "No branches to delete"
else
    echo -e "${YELLOW}The following branches will be deleted:${NC}"
    echo "$BRANCHES_TO_DELETE"

    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for branch in $BRANCHES_TO_DELETE; do
            echo -e "${YELLOW}Deleting branch: $branch${NC}"
            if git branch -D "$branch"; then
                success "Deleted branch: $branch"
            else
                error "Failed to delete branch: $branch"
            fi
        done
    else
        warning "Branch cleanup skipped"
    fi
fi

# Step 6: Return to original branch
echo -e "${YELLOW}Step 6: Returning to original branch${NC}"
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "stg" ]; then
    warning "Original branch $CURRENT_BRANCH might have been deleted"
    warning "Staying on main branch"
else
    if ! git checkout "$CURRENT_BRANCH"; then
        error "Failed to checkout original branch: $CURRENT_BRANCH"
        warning "Staying on main branch"
    else
        success "Returned to original branch: $CURRENT_BRANCH"
    fi
fi

success "All done!"
