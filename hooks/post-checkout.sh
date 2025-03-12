#!/bin/bash

# This hook is called after git checkout
# Args: $1 - ref of previous HEAD
#       $2 - ref of new HEAD
#       $3 - 1 if checkout was a branch checkout, 0 if file checkout

# Only run when checking out a branch (not a file)
if [ "$3" != "1" ]; then
    exit 0
fi

# Get the current branch
current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

# Only run when checking out main branch
if [ "$current_branch" = "main" ]; then
    # ANSI color codes
    GREEN="\033[0;32m"
    YELLOW="\033[0;33m"
    CYAN="\033[0;36m"
    NC="\033[0m" # No Color

    # Print directly to terminal
    tty_output="/dev/tty"

    echo "" > "$tty_output"
    echo -e "${YELLOW}🔄 You've checked out the main branch.${NC}" > "$tty_output"
    echo -e "${CYAN}According to our workflow, you should create a feature or fix branch.${NC}" > "$tty_output"
    echo "" > "$tty_output"

    # Ask if they want to create a branch now
    echo -e "${YELLOW}Would you like to create a branch now? (y/n):${NC} " > "$tty_output"

    # Read from terminal
    read -r create_branch < "/dev/tty"

    if [[ "$create_branch" =~ ^[Yy]$ ]]; then
        # Use the shell script version instead of Node.js
        echo -e "${GREEN}Launching branch creation tool...${NC}" > "$tty_output"
        bash "$(git rev-parse --show-toplevel)/scripts/create-branch.sh"
    else
        echo -e "${YELLOW}Staying on main branch. Remember to create a feature or fix branch before making changes.${NC}" > "$tty_output"
    fi
fi

exit 0
