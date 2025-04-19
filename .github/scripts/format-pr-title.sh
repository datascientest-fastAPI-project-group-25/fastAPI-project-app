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

# Extract branch type (feat, fix, docs, etc.)
BRANCH_TYPE=""
if [[ "$BRANCH_NAME" == feat/* || "$BRANCH_NAME" == feature/* ]]; then
  BRANCH_TYPE="feat"
elif [[ "$BRANCH_NAME" == fix/* || "$BRANCH_NAME" == hotfix/* ]]; then
  BRANCH_TYPE="fix"
elif [[ "$BRANCH_NAME" == docs/* ]]; then
  BRANCH_TYPE="docs"
elif [[ "$BRANCH_NAME" == style/* ]]; then
  BRANCH_TYPE="style"
elif [[ "$BRANCH_NAME" == refactor/* ]]; then
  BRANCH_TYPE="refactor"
elif [[ "$BRANCH_NAME" == perf/* ]]; then
  BRANCH_TYPE="perf"
elif [[ "$BRANCH_NAME" == test/* ]]; then
  BRANCH_TYPE="test"
elif [[ "$BRANCH_NAME" == build/* ]]; then
  BRANCH_TYPE="build"
elif [[ "$BRANCH_NAME" == ci/* ]]; then
  BRANCH_TYPE="ci"
elif [[ "$BRANCH_NAME" == chore/* ]]; then
  BRANCH_TYPE="chore"
elif [[ "$BRANCH_NAME" == revert/* ]]; then
  BRANCH_TYPE="revert"
else
  # Default to chore for unrecognized branch types
  BRANCH_TYPE="chore"
fi

# Get current version from VERSION file if it exists
VERSION=""
if [ -f "VERSION" ]; then
  VERSION=$(cat VERSION)
else
  VERSION="0.1.0"  # Default version if VERSION file doesn't exist
fi

# Format PR title based on target branch
if [ "$TARGET_BRANCH" == "main" ]; then
  # For PRs to main, use semantic version format
  if [ "$BRANCH_NAME" == "stg" ]; then
    # Special case for staging to main - use semantic version
    echo "release(prod): v${VERSION}"
  else
    # For other branches to main
    echo "release(prod): $BRANCH_NAME"
  fi
elif [ "$TARGET_BRANCH" == "stg" ]; then
  # For PRs to staging, include both type and staging indicator
  BRANCH_SUFFIX=$(echo "$BRANCH_NAME" | sed -E 's/^(feat|feature|fix|hotfix|docs|style|refactor|perf|test|build|ci|chore|revert)\///')
  echo "$BRANCH_TYPE(staging): $BRANCH_SUFFIX"
else
  # Default format for other target branches
  echo "$BRANCH_NAME → $TARGET_BRANCH"
fi
