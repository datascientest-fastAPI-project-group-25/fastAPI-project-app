#!/bin/bash

# This script checks the status of the prestart process
# and provides detailed information about the database and migrations

echo "===== Prestart Status Check ====="
echo "Checking database connection..."

# Check if PostgreSQL is running
if pg_isready -h ${POSTGRES_SERVER} -p 5432 -U ${POSTGRES_USER}; then
    echo "✅ Database is running"
else
    echo "❌ Database is not running or not accessible"
    echo "Connection details:"
    echo "  Host: ${POSTGRES_SERVER}"
    echo "  Port: 5432"
    echo "  User: ${POSTGRES_USER}"
    echo "  Database: ${POSTGRES_DB}"
    exit 1
fi

# Check if alembic directory exists and has required files
echo "Checking alembic setup..."
if [ -d "/app/backend/alembic" ]; then
    echo "✅ Alembic directory exists"

    if [ -f "/app/backend/alembic/env.py" ]; then
        echo "✅ Alembic env.py exists"
    else
        echo "❌ Alembic env.py is missing"
    fi

    if [ -f "/app/backend/alembic/script.py.mako" ]; then
        echo "✅ Alembic script.py.mako exists"
    else
        echo "❌ Alembic script.py.mako is missing"
    fi

    if [ -d "/app/backend/alembic/versions" ]; then
        echo "✅ Alembic versions directory exists"
        echo "   Versions found: $(ls -1 /app/backend/alembic/versions | wc -l)"
    else
        echo "❌ Alembic versions directory is missing"
    fi
else
    echo "❌ Alembic directory does not exist"
fi

# Check alembic history
echo "Checking alembic migration history..."
cd /app/backend && alembic history || echo "❌ Failed to get alembic history"

# Check current alembic revision
echo "Current alembic revision:"
cd /app/backend && alembic current || echo "❌ Failed to get current revision"

echo "===== Prestart Status Check Complete ====="
