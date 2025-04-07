#!/bin/bash
set -e

# Script to run frontend tests in a controlled environment
echo "Setting up frontend test environment..."

# Ensure we're in the project root directory
cd "$(dirname "$0")/.."

# Start backend services
echo "Starting backend services..."
docker compose up -d backend
echo "Waiting for backend to be ready..."
sleep 5

# Create a temporary container for testing
echo "Creating test container..."
docker run --rm -it \
  --network fastapi-project-app_default \
  -v "$(pwd):/app" \
  -w /app \
  -e PLAYWRIGHT_TIMEOUT=60000 \
  -e DEBUG=pw:api \
  -e VITE_API_URL=http://backend:8000 \
  mcr.microsoft.com/playwright:v1.42.1-focal \
  bash -c "cd frontend && \
    npm install -g pnpm && \
    pnpm install --no-frozen-lockfile && \
    mkdir -p /app/frontend/playwright/.auth && \
    pnpm exec playwright test --timeout=60000 --retries=1"

# Capture the exit code
TEST_EXIT_CODE=$?

echo "Cleaning up..."
docker compose down --remove-orphans

echo "Frontend tests completed with exit code: $TEST_EXIT_CODE"
exit $TEST_EXIT_CODE
