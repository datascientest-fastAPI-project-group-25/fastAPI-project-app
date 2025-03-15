# Stage 0: Base stage with Bun
FROM oven/bun:latest AS base

# Set up the monorepo structure
WORKDIR /app

# Copy root package.json and turbo.json first
COPY package*.json /app/
COPY turbo.json /app/

# Set up frontend workspace
WORKDIR /app/frontend

# Copy frontend package.json
COPY package*.json /app/frontend/

# Install dependencies and generate lockfile
WORKDIR /app
RUN bun install

# Copy frontend files
COPY ./ /app/frontend/

# Stage 1: Development stage for testing
FROM base AS development

ENV NODE_ENV=development

# Set working directory to frontend for running the dev server
WORKDIR /app/frontend

CMD ["bun", "--bun", "vite", "--host", "0.0.0.0"]

# Stage 2: Build stage for production
FROM base AS build-stage

ARG VITE_API_URL=${VITE_API_URL}

# Set working directory to frontend for building
WORKDIR /app/frontend

RUN bun run build

# Stage 3: Production stage with Traefik
# Traefik will handle the routing and serving
