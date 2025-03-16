#!/bin/sh

# Create the directory for Playwright auth storage if it doesn't exist
mkdir -p playwright/.auth

# For Alpine Linux, we need to install dependencies manually
if [ -f "/etc/alpine-release" ]; then
  echo "Installing Alpine dependencies for Playwright..."
  apk add --no-cache \
    chromium \
    firefox \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    font-noto-emoji \
    wqy-zenhei \
    libstdc++ \
    dbus \
    xvfb \
    gtk+3.0 \
    alsa-lib \
    libxkbcommon \
    mesa-gl \
    mesa-egl \
    pango \
    cairo \
    bash

  # Set environment variables for Playwright to use the system-installed browsers
  export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
  export PLAYWRIGHT_BROWSERS_PATH=/usr/bin

  # Create a file to persist these environment variables
  echo "export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1" > /app/frontend/.playwright-env
  echo "export PLAYWRIGHT_BROWSERS_PATH=/usr/bin" >> /app/frontend/.playwright-env
else
  # For non-Alpine systems, use the standard installation
  echo "Installing Playwright browsers..."
  npx playwright install --with-deps
fi

echo "Playwright setup complete."
