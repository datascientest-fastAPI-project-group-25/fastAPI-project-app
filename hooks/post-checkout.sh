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

# Check if current branch is main or dev
if [ "$current_branch" = "main" ] || [ "$current_branch" = "dev" ]; then
    # ANSI color codes
    RED="\033[0;31m"
    YELLOW="\033[0;33m"
    CYAN="\033[0;36m"
    NC="\033[0m" # No Color

    # Print directly to terminal
    tty_output="/dev/tty"

    echo "" > "$tty_output"
    echo -e "${RED}⚠️  WARNING: You've checked out the ${current_branch} branch.${NC}" > "$tty_output"
    echo -e "${YELLOW}According to our branching strategy:${NC}" > "$tty_output"
    echo -e "${CYAN}1. Direct pushes to ${current_branch} are not allowed${NC}" > "$tty_output"
    echo -e "${CYAN}2. You should work in feature (feat/*) or fix branches${NC}" > "$tty_output"
    echo -e "${CYAN}3. These branches will automatically open PRs to dev when pushed${NC}" > "$tty_output"
    echo "" > "$tty_output"
    echo -e "${YELLOW}Please use the following make command to create a proper branch:${NC}" > "$tty_output"
    echo -e "${CYAN}  make branch-create${NC}" > "$tty_output"
    echo "" > "$tty_output"
    echo -e "${YELLOW}See README.md#-branching-strategy for details on our branching strategy.${NC}" > "$tty_output"
    echo "" > "$tty_output"
fi

exit 0
