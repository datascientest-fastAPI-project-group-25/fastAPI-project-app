#!/bin/sh

# Print status message
echo "Starting prestart script..."

# Ensure PYTHONPATH is set correctly and print it for debugging
echo "PYTHONPATH before: $PYTHONPATH"

# Check Python version
echo "Using Python $(python --version) environment at: $(which python | xargs dirname)"

# Print environment variables for debugging
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_SERVER: $POSTGRES_SERVER"
echo "POSTGRES_DB: $POSTGRES_DB"

# Exit immediately if a command exits with a non-zero status
set -e

# Print current directory and files for debugging
echo "Current directory: $(pwd)"
echo "Listing alembic directory:"
ls -la /app/backend/alembic/

# Run migrations
echo "Running database migrations..."
cd /app/backend
alembic -c alembic.ini upgrade head

# Check if migrations were successful
if [ $? -ne 0 ]; then
    echo "Migration failed! Check the error messages above."
    exit 1
else
    echo "Migrations completed successfully."
fi

# Create initial data in DB
python /app/backend/app/backend_pre_start.py

# Start the FastAPI application
exec uvicorn app.main:app --host 0.0.0.0 --port 8000
