#! /usr/bin/env bash

# Enable error reporting but not verbose output to reduce log noise
set -e

echo "=== Starting prestart script ==="

# Function to handle errors
handle_error() {
  echo "ERROR: Prestart script failed at line $1 with exit code $2"
  exit $2
}

# Set trap for error handling
trap 'handle_error ${LINENO} $?' ERR

echo "Waiting for database to be ready..."
# Let the DB start with a timeout
TIMEOUT=120  # Increased timeout for slower environments
COUNTER=0
until python app/backend_pre_start.py 2>/dev/null || [ $COUNTER -eq $TIMEOUT ]; do
  if [ $(($COUNTER % 5)) -eq 0 ]; then
    echo "Waiting for database connection... ($COUNTER/$TIMEOUT)"
  fi
  sleep 1
  COUNTER=$((COUNTER+1))
done

if [ $COUNTER -eq $TIMEOUT ]; then
  echo "ERROR: Database connection timed out after $TIMEOUT seconds"
  echo "Check your database configuration and ensure PostgreSQL is running"
  exit 1
fi

echo "Database is ready, running migrations..."
# Run migrations with error handling
if ! alembic upgrade head; then
  echo "ERROR: Database migration failed"
  exit 1
fi

echo "Creating initial data..."
# Create initial data in DB with error handling
if ! python app/initial_data.py; then
  echo "ERROR: Failed to create initial data"
  exit 1
fi

echo "✅ Prestart completed successfully"
