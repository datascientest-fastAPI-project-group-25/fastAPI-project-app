#!/usr/bin/env bash

# Script to check the status of the prestart container and display a more meaningful message
# Usage: ./scripts/check-prestart-status.sh

# Get the container name
CONTAINER_NAME="fastapi-project-app-prestart-1"

# Check if the container exists
if ! docker ps -a --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
    echo "Prestart container not found. Make sure the application is running."
    exit 1
fi

# Get the exit code of the prestart container
EXIT_CODE=$(docker inspect --format='{{.State.ExitCode}}' $CONTAINER_NAME)

# Check if the prestart container exited successfully
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "============================================="
    echo "✅ Prestart Status: DONE"
    echo "Database initialization and migrations completed successfully."
    echo "============================================="
else
    echo "============================================="
    echo "❌ Prestart Status: FAILED (Exit Code: $EXIT_CODE)"
    echo "Database initialization and migrations failed. Check the logs for more details:"
    echo "docker compose logs prestart"
    echo "============================================="
fi
