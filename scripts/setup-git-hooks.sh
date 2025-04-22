#!/bin/bash
set -e

# Set up the version merge driver
git config --local merge.version-merge.name "Version file merger"
git config --local merge.version-merge.driver "$(pwd)/scripts/git-hooks/version-merge-driver.sh %O %A %B %P"

echo "Git hooks and merge drivers set up successfully!"
