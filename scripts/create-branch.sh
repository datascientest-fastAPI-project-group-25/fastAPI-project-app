#!/bin/bash

# Script to create a new feature or fix branch from main

# Ensure we're up to date with main
git fetch origin
git checkout main
git pull origin main

# Ask user for branch type
echo "Choose branch type:"
echo "1) Feature branch (feat/)"
echo "2) Fix branch (fix/)"
read -p "Enter choice [1-2]: " branch_type

# Ask for branch name
read -p "Enter branch name (without prefix): " branch_name

# Ask for automerge option for fix branches
automerge=""
if [ "$branch_type" = "2" ]; then
  echo "Do you want to enable automerge for this fix?"
  echo "1) Yes - automatically merge after tests pass"
  echo "2) No - require approval"
  read -p "Enter choice [1-2]: " automerge_choice

  if [ "$automerge_choice" = "1" ]; then
    automerge="-automerge"
  fi
fi

# Create branch with appropriate prefix
if [ "$branch_type" = "1" ]; then
  git checkout -b "feat/$branch_name"
  echo "Created feature branch: feat/$branch_name"
elif [ "$branch_type" = "2" ]; then
  git checkout -b "fix/$branch_name$automerge"
  echo "Created fix branch: fix/$branch_name$automerge"
else
  echo "Invalid choice. Exiting."
  exit 1
fi

# Remind user about commit format
echo ""
echo "Remember to use conventional commits format:"
echo "  feat(scope): your feature description"
echo "  fix(scope): your fix description"
echo ""
echo "Other types: docs, style, refactor, perf, test, build, ci, chore, revert"
