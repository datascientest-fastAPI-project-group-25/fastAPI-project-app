#!/usr/bin/env bash
set -euo pipefail

# This script extracts the conventional commit type from a branch name
# Usage: ./extract_commit_type.sh BRANCH_NAME
# Example: ./extract_commit_type.sh feat/add-new-feature
#          ./extract_commit_type.sh fix-bug-123
#          ./extract_commit_type.sh chore_update_deps

# Check if branch name is provided
if [ $# -lt 1 ]; then
  echo "::error::Branch name not provided"
  echo "Usage: $0 BRANCH_NAME"
  exit 1
fi

BRANCH_NAME=$1
echo "Analyzing branch name: $BRANCH_NAME"

# Define conventional commit types and their corresponding semantic version bump
declare -A COMMIT_TYPES=(
  ["feat"]="minor"
  ["feature"]="minor"
  ["fix"]="patch"
  ["bugfix"]="patch"
  ["perf"]="patch"
  ["refactor"]="patch"
  ["style"]="patch"
  ["test"]="patch"
  ["docs"]="patch"
  ["chore"]="patch"
  ["ci"]="patch"
  ["build"]="patch"
)

# Extract commit type from branch name
# Look for patterns like:
# - feat/branch-name
# - feat-branch-name
# - feat_branch_name
# - feature/branch-name

# First, convert any separators to a standard one
NORMALIZED_BRANCH=$(echo "$BRANCH_NAME" | sed 's/[\/\-_]/ /g')
echo "Normalized branch name: $NORMALIZED_BRANCH"

# Extract the first word, which might be the commit type
FIRST_WORD=$(echo "$NORMALIZED_BRANCH" | awk '{print $1}')
echo "First word in branch name: $FIRST_WORD"

# Check if it's a known commit type
COMMIT_TYPE=""
VERSION_BUMP=""

for TYPE in "${!COMMIT_TYPES[@]}"; do
  if [[ "$FIRST_WORD" == "$TYPE" ]]; then
    COMMIT_TYPE="$TYPE"
    VERSION_BUMP="${COMMIT_TYPES[$TYPE]}"
    break
  fi
done

# If no commit type was found, check if the branch name contains a commit type
if [[ -z "$COMMIT_TYPE" ]]; then
  for TYPE in "${!COMMIT_TYPES[@]}"; do
    if [[ "$BRANCH_NAME" == *"$TYPE"* ]]; then
      COMMIT_TYPE="$TYPE"
      VERSION_BUMP="${COMMIT_TYPES[$TYPE]}"
      break
    fi
  done
fi

# If still no commit type was found, default to patch
if [[ -z "$COMMIT_TYPE" ]]; then
  COMMIT_TYPE="chore"
  VERSION_BUMP="patch"
  echo "No conventional commit type found in branch name. Defaulting to 'chore' (patch bump)."
else
  echo "Found conventional commit type: $COMMIT_TYPE (${VERSION_BUMP} bump)"
fi

# Set outputs
echo "commit_type=$COMMIT_TYPE" >> "$GITHUB_OUTPUT"
echo "version_bump=$VERSION_BUMP" >> "$GITHUB_OUTPUT"

# For breaking changes, override to major if the branch name contains 'breaking' or '!'
if [[ "$BRANCH_NAME" == *"breaking"* || "$BRANCH_NAME" == *"!"* ]]; then
  echo "Breaking change detected in branch name!"
  echo "version_bump=major" >> "$GITHUB_OUTPUT"
fi
