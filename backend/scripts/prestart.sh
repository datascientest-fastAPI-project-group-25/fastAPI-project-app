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

# Print environment variables for debugging
echo "Database connection settings:"
echo "POSTGRES_SERVER: $POSTGRES_SERVER"
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_DB: $POSTGRES_DB"

# Try a direct connection with psycopg
python -c "import psycopg; print('Testing direct connection...'); conn = psycopg.connect('host=$POSTGRES_SERVER user=$POSTGRES_USER password=$POSTGRES_PASSWORD dbname=$POSTGRES_DB'); print('Direct connection successful!')" || echo "Direct connection failed"

until uv run --app app --path app/backend_pre_start.py 2>&1 || [ $COUNTER -eq $TIMEOUT ]; do
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
# Run migrations and capture output
MIGRATION_OUTPUT=$(alembic upgrade head 2>&1) || {
  # Check if the error was because tables already exist
  if echo "$MIGRATION_OUTPUT" | grep -q "relation.*already exists"; then
    echo "Tables already exist, continuing with startup"
  else
    echo "ERROR: Database migration failed with unexpected error"
    echo "$MIGRATION_OUTPUT"
    exit 1
  fi
}

echo "Creating initial data..."
# Create initial data in DB with error handling
if ! uv run --app app --path app/initial_data.py; then
  echo "ERROR: Failed to create initial data"
  exit 1
fi

echo " Prestart completed successfully"
