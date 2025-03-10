#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to validate branch name
validate_branch_name() {
    local name=$1
    if [[ ! $name =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        echo -e "${RED}Invalid branch name. Use lowercase letters, numbers, and hyphens only.${NC}"
        return 1
    fi
    return 0
}

# Function to handle unstaged changes
handle_unstaged_changes() {
    if ! git diff-index --quiet HEAD --; then
        echo -e "${YELLOW}You have unstaged changes. Choose an action:${NC}"
        select action in "stash" "commit" "abort"; do
            case $action in
                "stash")
                    echo -e "${BLUE}Stashing changes...${NC}"
                    git stash
                    return 0
                    ;;
                "commit")
                    echo -e "${BLUE}Committing changes...${NC}"
                    git add .
                    git commit -m "chore: save work in progress"
                    return 0
                    ;;
                "abort")
                    echo -e "${RED}Aborting...${NC}"
                    exit 1
                    ;;
                *)
                    echo -e "${RED}Invalid option${NC}"
                    ;;
            esac
        done
    fi
    return 0
}

# Ensure we're in the git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
}

# Handle any unstaged changes
handle_unstaged_changes

# Check if dev branch exists
if ! git show-ref --verify --quiet refs/heads/dev; then
    echo -e "${YELLOW}Dev branch doesn't exist. Would you like to create it? (y/n): ${NC}"
    read -r create_dev
    if [[ $create_dev =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Creating dev branch from main...${NC}"
        git checkout main
        git pull
        git checkout -b dev
        git push -u origin dev
    else
        echo -e "${RED}Cannot proceed without dev branch. Aborting...${NC}"
        exit 1
    fi
else
    # Switch to dev branch and pull latest changes
    echo -e "${BLUE}Switching to dev branch and pulling latest changes...${NC}"
    git checkout dev
    git pull
fi

# Ask if user wants to create a new feature/fix branch
read -r -p "Do you want to create a new feature/fix branch? (y/n): " create_new

if [[ $create_new =~ ^[Yy]$ ]]; then
    # Ask for branch type
    echo -e "${BLUE}Select branch type:${NC}"
    PS3="Enter number: "
    options=("feature" "fix" "quit")
    select opt in "${options[@]}"
    do
        case $opt in
            "feature")
                prefix="feat"
                break
                ;;
            "fix")
                prefix="fix"
                break
                ;;
            "quit")
                echo -e "${YELLOW}Exiting...${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
    done

    # Get branch name and validate
    while true; do
        read -r -p "Enter branch name (lowercase, hyphens allowed): " branch_name
        if validate_branch_name "$branch_name"; then
            break
        fi
    done

    # Check if branch already exists
    new_branch="${prefix}/${branch_name}"
    if git show-ref --verify --quiet refs/heads/"$new_branch"; then
        echo -e "${RED}Error: Branch ${new_branch} already exists${NC}"
        exit 1
    fi

    # Create and checkout new branch
    echo -e "${BLUE}Creating new branch: ${new_branch}${NC}"
    git checkout -b "$new_branch"
    echo -e "${GREEN}Successfully created and switched to ${new_branch}${NC}"
    echo -e "${YELLOW}Tip: Push your changes with 'git push -u origin ${new_branch}'${NC}"
else
    echo -e "${GREEN}Continuing work on dev branch${NC}"
fi
