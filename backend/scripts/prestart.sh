#!/bin/sh

# Print status message
echo "Starting prestart script..."

# Ensure PYTHONPATH is set correctly and print it for debugging
echo "PYTHONPATH before: $PYTHONPATH"

# Create alembic directory structure if it doesn't exist
mkdir -p /app/backend/alembic/versions

# Copy necessary files from app/alembic to the alembic directory
if [ ! -f "/app/backend/alembic/env.py" ]; then
    echo "Copying alembic environment files..."
    cp /app/backend/app/alembic/env.py /app/backend/alembic/
    cp /app/backend/app/alembic/script.py.mako /app/backend/alembic/
fi

# Print environment variables for debugging
echo "POSTGRES_USER: $POSTGRES_USER"
echo "POSTGRES_SERVER: $POSTGRES_SERVER"

export PYTHONPATH="/app:/app/backend:$PYTHONPATH"

# Activate the virtual environment if it exists
if [ -d "/app/.venv" ]; then
    . /app/.venv/bin/activate
fi

echo "PYTHONPATH after: $PYTHONPATH"

# Exit immediately if a command exits with a non-zero status
set -e

# Print current directory and files for debugging
echo "Current directory: $(pwd)"
echo "Listing alembic directory:"
ls -la /app/backend/alembic/

# Run migrations
echo "Running database migrations..."
cd /app/backend && PYTHONPATH=/app:/app/backend alembic upgrade head

if [ $? -ne 0 ]; then
    echo "Migration failed! Check the error messages above."
else
    echo "Migrations completed successfully."
fi

# Create initial data in DB
python /app/backend/app/backend_pre_start.py
