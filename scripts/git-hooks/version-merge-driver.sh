#!/bin/bash
set -e

# This script is a custom merge driver for the VERSION file
# It always keeps the higher version number

# $1 = %O (base version)
# $2 = %A (current version - usually the target branch)
# $3 = %B (other version - usually the source branch)
# $4 = conflict marker size (unused)

BASE_VERSION=$(cat "$1" | tr -d '\n')
CURRENT_VERSION=$(cat "$2" | tr -d '\n')
OTHER_VERSION=$(cat "$3" | tr -d '\n')

echo "Ancestor version: $BASE_VERSION"
echo "Current version: $CURRENT_VERSION"
echo "Other version: $OTHER_VERSION"

# Compare versions using sort -V (version sort)
HIGHER_VERSION=$(printf "%s\n%s\n" "$CURRENT_VERSION" "$OTHER_VERSION" | sort -V | tail -n1)

echo "Keeping higher version: $HIGHER_VERSION"
echo "$HIGHER_VERSION" > "$2"

# Return success
exit 0
