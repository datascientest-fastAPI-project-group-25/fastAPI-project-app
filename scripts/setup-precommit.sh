#!/bin/bash
set -e

echo "Setting up pre-commit git hooks manager..."
cd "$(git rev-parse --show-toplevel)"

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "pre-commit not found, installing..."

    # Check if pip is available
    if command -v pip &> /dev/null; then
        pip install pre-commit
    elif command -v pip3 &> /dev/null; then
        pip3 install pre-commit
    # Fall back to brew if available
    elif command -v brew &> /dev/null; then
        brew install pre-commit
    else
        echo "Error: Could not install pre-commit. Please install pip or brew first."
        exit 1
    fi
fi

echo "Installing git hooks with pre-commit..."
pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push

echo "✅ Git hooks have been successfully installed!"
echo "🚀 You're all set to start developing with automatic code quality checks."
