#!/bin/bash

# Script to run tests with test environment variables
# This is used by the pre-commit hook to ensure tests have the required environment variables

# Change to the project root directory
cd "$(dirname "$0")/.." || exit 1

# Load environment variables from .env.test if it exists
if [ -f .env.test ]; then
  echo "Loading test environment variables from .env.test"
  export $(grep -v '^#' .env.test | xargs)
else
  echo "Warning: .env.test file not found. Tests may fail due to missing environment variables."
fi

# For pre-commit checks, we only want to run basic tests that don't require a database
# This includes syntax checks, linting, and unit tests that don't need DB access
echo "Running pre-commit tests (skipping database tests)..."
pytest "$@" -k "test_password_hashing or test_authentication" backend/app/test_auth.py

# Store the exit code
exit_code=$?

# Return the exit code from pytest
exit $exit_code
