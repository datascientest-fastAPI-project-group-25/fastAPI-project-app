#!/bin/bash
# Custom merge driver for VERSION file
# This script automatically resolves conflicts in the VERSION file
# by keeping the higher version number

# Parameters passed by Git:
# $1 - %O - name of the temporary file containing the common ancestor version
# $2 - %A - name of the temporary file containing the version from the current branch
# $3 - %B - name of the temporary file containing the version from the branch being merged

# Read the versions
ANCESTOR_VERSION=$(cat "$1" | tr -d '\n')
CURRENT_VERSION=$(cat "$2" | tr -d '\n')
OTHER_VERSION=$(cat "$3" | tr -d '\n')

echo "Ancestor version: $ANCESTOR_VERSION"
echo "Current version: $CURRENT_VERSION"
echo "Other version: $OTHER_VERSION"

# Function to compare version numbers
# Returns 1 if version1 > version2, 0 if equal, -1 if version1 < version2
compare_versions() {
    local version1=$1
    local version2=$2

    # Split versions into arrays
    IFS='.' read -ra v1_parts <<< "$version1"
    IFS='.' read -ra v2_parts <<< "$version2"

    # Compare each part
    for ((i=0; i<${#v1_parts[@]} || i<${#v2_parts[@]}; i++)); do
        local v1_part=${v1_parts[$i]:-0}
        local v2_part=${v2_parts[$i]:-0}

        if [[ $v1_part -gt $v2_part ]]; then
            echo 1
            return
        elif [[ $v1_part -lt $v2_part ]]; then
            echo -1
            return
        fi
    done

    # Versions are equal
    echo 0
}

# Compare versions
COMPARISON=$(compare_versions "$CURRENT_VERSION" "$OTHER_VERSION")

# Determine which version to keep
if [[ $COMPARISON -ge 0 ]]; then
    # Current version is higher or equal, keep it
    echo "Keeping current version: $CURRENT_VERSION"
    echo "$CURRENT_VERSION" > "$2"
else
    # Other version is higher, use it
    echo "Using other version: $OTHER_VERSION"
    echo "$OTHER_VERSION" > "$2"
fi

# Exit with success
exit 0
