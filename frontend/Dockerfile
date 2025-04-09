# syntax=docker/dockerfile:1

# --- Base Stage --- #
FROM --platform=linux/amd64 node:18-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# --- Dependencies Stage --- #
FROM base AS deps

# Copy dependency definition files
# Need root package.json for workspace definition and frontend package.json
COPY package.json pnpm-lock.yaml* ./
COPY frontend/package.json ./frontend/

# Fetch production dependencies using the lockfile
# This leverages pnpm's content-addressable store for caching
RUN pnpm fetch --prod

# --- Builder Stage --- #
FROM base AS builder

# Install production dependencies using the offline cache from 'deps' stage
# Copy the full pnpm virtual store
COPY --from=deps /app/.pnpm-store /.pnpm-store

# Copy dependency files again (needed for install command)
COPY package.json pnpm-lock.yaml* ./
COPY frontend/package.json ./frontend/

# Install only production dependencies, using the offline store
# --ignore-scripts to prevent husky, etc.
RUN pnpm install --prod --frozen-lockfile --offline --ignore-scripts

# Copy frontend source code
# Ensure backend or other unrelated files are not copied if present in root
COPY ./frontend ./frontend

# Build the frontend application
WORKDIR /app/frontend
RUN pnpm run build

# --- Final/Production Stage --- #
FROM base AS final

WORKDIR /app

# Set NODE_ENV for production
ENV NODE_ENV=production

# Install 'serve' for serving static files
# We only need serve in the final image
RUN pnpm add -g serve

# Copy built artifacts from the builder stage
COPY --from=builder /app/frontend/dist ./frontend/dist

# Expose the port the app runs on
EXPOSE 5173

# Start command using serve
# Adjust the path if the dist directory structure is different
CMD ["serve", "-s", "frontend/dist", "-l", "5173"]
