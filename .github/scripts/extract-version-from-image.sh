#!/bin/bash
set -e

# This script extracts the version from a Docker image by inspecting its labels
# Usage: ./extract-version-from-image.sh <image-name>

IMAGE_NAME=$1

if [ -z "$IMAGE_NAME" ]; then
  echo "Error: Image name is required"
  echo "Usage: ./extract-version-from-image.sh <image-name>"
  exit 1
fi

# Pull the image if not already available
echo "Pulling image: $IMAGE_NAME"
docker pull "$IMAGE_NAME"

# Extract the version from the image labels
VERSION=$(docker inspect --format='{{index .Config.Labels "org.opencontainers.image.version"}}' "$IMAGE_NAME")

# Output the version
echo "Image version: $VERSION"

# Return the version
echo "$VERSION"
