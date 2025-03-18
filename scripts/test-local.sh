#!/bin/bash

# Exit on error
set -e

echo "Running local tests..."

# Ensure we're using test environment
cp .env.test .env

# Rebuild backend with test target and start services
echo "Building and starting services..."
docker compose build --build-arg TARGET=test backend
docker compose up -d

# Run backend tests
echo "Running backend tests..."
docker compose exec -T backend bash -c "cd /app && pytest app/tests/"

# Run backend linting
echo "Running backend linting..."
docker compose exec -T backend bash -c "cd /app && ruff check app"
docker compose exec -T backend bash -c "cd /app && black --check app"
docker compose exec -T backend bash -c "cd /app && bandit -r app -x app/tests"

# Run frontend tests
echo "Running frontend tests..."
docker compose exec -T frontend bash -c "cd /app && pnpm install --frozen-lockfile"
docker compose exec -T frontend bash -c "cd /app && pnpm run lint"
docker compose exec -T frontend bash -c "cd /app && pnpm run format:check"

echo "All tests completed!"