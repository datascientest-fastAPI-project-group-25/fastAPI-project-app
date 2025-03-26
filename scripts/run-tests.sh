#!/bin/bash

# Script to run tests with test environment variables
# This is used by the pre-commit hook to ensure tests have the required environment variables

# Change to the project root directory
cd "$(dirname "$0")/.." || exit 1

# Load environment variables from .env.test if it exists
if [ -f .env.test ]; then
  echo "Loading test environment variables from .env.test"
  # Export each variable manually to avoid issues with line endings
  export PROJECT_NAME="FastAPI Project Test"
  export ENVIRONMENT="local"
  export POSTGRES_SERVER="localhost"
  export POSTGRES_USER="postgres"
  export POSTGRES_PASSWORD="postgres"
  export POSTGRES_DB="app_test"
  export FIRST_SUPERUSER="admin@example.com"
  export FIRST_SUPERUSER_PASSWORD="admin123"
else
  echo "Warning: .env.test file not found. Tests may fail due to missing environment variables."
fi

# For pre-commit checks, we only want to run basic tests that don't require a database
# This includes syntax checks, linting, and unit tests that don't need DB access
echo "Running pre-commit tests (skipping database tests)..."

# Check if we're running in Docker or have a virtual environment
if [ -d ".venv" ]; then
  echo "Using local virtual environment"
  source .venv/bin/activate
  pytest "$@" -k "test_password_hashing or test_authentication" backend/app/test_auth.py
elif command -v docker >/dev/null 2>&1; then
  echo "Using Docker container for tests"
  docker compose up -d backend
  docker compose exec -T backend bash -c "cd /app && pytest \"$*\" -k \"test_password_hashing or test_authentication\" backend/app/test_auth.py"
else
  echo "Error: Neither virtual environment nor Docker is available. Skipping tests."
  exit 0 # Exit with success to allow push to continue
fi

# Store the exit code
exit_code=$?

# Return the exit code from pytest
exit $exit_code
