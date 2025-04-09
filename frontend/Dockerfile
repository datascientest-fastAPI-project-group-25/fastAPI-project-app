# syntax=docker/dockerfile:1

# --- Base Stage --- #
FROM --platform=linux/amd64 node:18-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Set up pnpm global bin directory
ENV PNPM_HOME=/usr/local/bin \
    PATH="/usr/local/bin:$PATH"

WORKDIR /app

# --- Dependencies Stage --- #
FROM base AS deps

# Copy dependency definition files
# When using frontend directory as context, paths are relative to that directory
COPY package.json ../
COPY pnpm-lock.yaml ..//
COPY package.json ./

# Fetch production dependencies using the lockfile
# This leverages pnpm's content-addressable store for caching
RUN pnpm fetch --prod

# Store pnpm store path for later stages
RUN echo $(pnpm store path) > /tmp/pnpm-store-path

# --- Builder Stage --- #
FROM base AS builder

# Install production dependencies using the offline cache from 'deps' stage
# Copy the full pnpm virtual store (using the correct path from deps stage)
COPY --from=deps /tmp/pnpm-store-path /tmp/pnpm-store-path
RUN mkdir -p $(cat /tmp/pnpm-store-path)
COPY --from=deps $(cat /tmp/pnpm-store-path) $(cat /tmp/pnpm-store-path)

# Copy dependency files again (needed for install command)
# Fix the path syntax for multiple files
COPY package.json ../
COPY pnpm-lock.yaml ..//
COPY package.json ./

# Install only production dependencies, using the offline store
# --ignore-scripts to prevent husky, etc.
RUN pnpm install --frozen-lockfile --offline --ignore-scripts || pnpm install --frozen-lockfile --ignore-scripts

# Copy frontend source code
# When using frontend directory as context, copy everything from current directory
COPY . .

# Build the frontend application
# Already in the frontend directory when using frontend as context
WORKDIR /app
RUN pnpm run build

# --- Final/Production Stage --- #
FROM base AS final

WORKDIR /app

# Set NODE_ENV for production
ENV NODE_ENV=production

# Install 'serve' for serving static files
# We only need serve in the final image
RUN pnpm install -g serve

# Copy built artifacts from the builder stage
COPY --from=builder /app/dist ./dist/

# Expose the port the app runs on
EXPOSE 5173

# Start command using serve
# Adjust the path if the dist directory structure is different
CMD ["serve", "-s", "frontend/dist", "-l", "5173"]
