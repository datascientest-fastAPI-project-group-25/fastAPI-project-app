#!/bin/bash
set -e

echo "Installing dependencies..."
cd scripts
npm install --save-dev vitest typescript
echo "Running tests..."
npx vitest run
