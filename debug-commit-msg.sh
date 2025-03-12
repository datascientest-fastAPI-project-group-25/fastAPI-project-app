#!/bin/bash

# Create a temporary commit message file
echo "fix: Address line length issues in GitHub Actions workflow files" > /tmp/commit_msg_test

# Set debug mode for pre-commit
export PRE_COMMIT_COLOR=always

# Run the commit-msg hook manually with the test file
pre-commit run --hook-stage commit-msg --commit-msg-filename /tmp/commit_msg_test

# Check the exit code
echo "Exit code: $?"

# Clean up
rm /tmp/commit_msg_test
