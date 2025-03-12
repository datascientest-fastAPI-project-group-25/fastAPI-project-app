#!/bin/bash
set -e

echo "Setting up Lefthook git hooks manager..."
cd "$(git rev-parse --show-toplevel)"

# Check if Lefthook is installed
if ! command -v lefthook &> /dev/null; then
    echo "Lefthook not found, installing..."
    
    # Check if npm is available
    if command -v npm &> /dev/null; then
        npm install -g @arkweid/lefthook
    # Check if go is available
    elif command -v go &> /dev/null; then
        go install github.com/evilmartians/lefthook@latest
    # Fall back to brew if available
    elif command -v brew &> /dev/null; then
        brew install lefthook
    else
        echo "Error: Could not install Lefthook. Please install npm, go, or brew first."
        exit 1
    fi
fi

# Install the hooks
echo "Installing git hooks..."
lefthook install

# Check if yamllint is installed (needed for YAML validation)
if ! command -v yamllint &> /dev/null; then
    echo "yamllint not found, installing..."
    if command -v pip &> /dev/null; then
        pip install yamllint
    elif command -v brew &> /dev/null; then
        brew install yamllint
    else
        echo "Warning: Could not install yamllint. YAML validation will be skipped."
    fi
fi

echo "✅ Lefthook git hooks installed successfully!"
echo "These hooks will run automatically on commit and push to ensure code quality."
echo "You can run them manually with: lefthook run pre-commit"
