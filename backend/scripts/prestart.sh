#! /usr/bin/env bash

# Enable error reporting and verbose output
set -e
set -x

echo "Waiting for database to be ready..."
# Let the DB start with a timeout
TIMEOUT=60
COUNTER=0
until python app/backend_pre_start.py || [ $COUNTER -eq $TIMEOUT ]; do
  echo "Waiting for database connection... ($COUNTER/$TIMEOUT)"
  sleep 1
  COUNTER=$((COUNTER+1))
done

if [ $COUNTER -eq $TIMEOUT ]; then
  echo "Database connection timed out after $TIMEOUT seconds"
  exit 1
fi

echo "Database is ready, running migrations..."
# Run migrations
alembic upgrade head

echo "Creating initial data..."
# Create initial data in DB
python app/initial_data.py

echo "Prestart completed successfully"
