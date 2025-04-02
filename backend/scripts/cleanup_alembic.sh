#!/bin/bash

# Script to consolidate Alembic configurations
echo "Cleaning up duplicate Alembic configurations..."

# Ensure we're in the app directory
cd /app || exit 1

# Create alembic directory if it doesn't exist
if [ ! -d "/app/alembic" ]; then
    echo "Creating main alembic directory..."
    mkdir -p /app/alembic/versions
fi

# Check if app/alembic exists (in case it's still in the old structure)
if [ -d "/app/app/alembic" ]; then
    # Ensure the main alembic directory has all necessary files
    if [ ! -f "/app/alembic/env.py" ] && [ -f "/app/app/alembic/env.py" ]; then
        echo "Copying env.py to main alembic directory..."
        cp /app/app/alembic/env.py /app/alembic/
    fi

    if [ ! -f "/app/alembic/script.py.mako" ] && [ -f "/app/app/alembic/script.py.mako" ]; then
        echo "Copying script.py.mako to main alembic directory..."
        cp /app/app/alembic/script.py.mako /app/alembic/
    fi

    # Copy any missing migration versions
    if [ -d "/app/app/alembic/versions" ]; then
        echo "Copying any missing migration versions..."
        mkdir -p /app/alembic/versions
        cp -n /app/app/alembic/versions/*.py /app/alembic/versions/ 2>/dev/null || true
    fi

    echo "Alembic configurations consolidated successfully!"
else
    echo "App alembic directory doesn't exist. No cleanup needed."
fi
