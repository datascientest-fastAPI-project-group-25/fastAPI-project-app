#!/bin/bash

# This script formats PR titles consistently across workflows
# Usage: ./format-pr-title.sh <branch_name> <target_branch>

set -e

BRANCH_NAME=$1
TARGET_BRANCH=$2

if [ -z "$BRANCH_NAME" ] || [ -z "$TARGET_BRANCH" ]; then
  echo "Error: Both branch name and target branch are required"
  echo "Usage: ./format-pr-title.sh <branch_name> <target_branch>"
  exit 1
fi

# Extract branch type (feat, fix, etc.)
BRANCH_TYPE=""
if [[ "$BRANCH_NAME" == feat/* || "$BRANCH_NAME" == feature/* ]]; then
  BRANCH_TYPE="feat"
elif [[ "$BRANCH_NAME" == fix/* || "$BRANCH_NAME" == hotfix/* ]]; then
  BRANCH_TYPE="fix"
else
  BRANCH_TYPE="chore"
fi

# Format PR title based on target branch
if [ "$TARGET_BRANCH" == "main" ]; then
  # For PRs to main, use "Release" format
  if [ "$BRANCH_NAME" == "stg" ]; then
    # Special case for staging to main
    echo "Release: Production deployment"
  else
    # For other branches to main
    echo "Release: $BRANCH_NAME"
  fi
elif [ "$TARGET_BRANCH" == "stg" ]; then
  # For PRs to staging, use "[branch-type]: [branch-name]" format
  # Remove the branch type prefix if it exists in the branch name
  BRANCH_SUFFIX=$(echo "$BRANCH_NAME" | sed -E 's/^(feat|feature|fix|hotfix)\///')
  echo "$BRANCH_TYPE: $BRANCH_SUFFIX"
else
  # Default format for other target branches
  echo "$BRANCH_NAME → $TARGET_BRANCH"
fi
