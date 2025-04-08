# Stage 0: Dependencies stage
FROM --platform=linux/amd64 node:18-alpine AS deps

# Install pnpm and TypeScript globally
RUN corepack enable && corepack prepare pnpm@8.11.0 --activate
# Set up PNPM_HOME and add it to PATH
ENV PNPM_HOME=/usr/local/bin
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm install -g typescript@latest

# Set environment variables to avoid optional dependency issues
ENV ROLLUP_SKIP_NODEJS=true
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Set up workspace
WORKDIR /app

# Copy package.json files
COPY package.json pnpm-lock.yaml* ./
COPY frontend/package.json ./frontend/

# Install root dependencies
RUN pnpm install --frozen-lockfile --prefer-offline --no-optional --force

# Ensure frontend dependencies are installed
WORKDIR /app/frontend
RUN pnpm install --prefer-offline --no-optional --force

# Switch back to root workspace
WORKDIR /app

# Stage 1: Builder stage
FROM --platform=linux/amd64 node:18-alpine AS builder

# Install pnpm and TypeScript globally
RUN corepack enable && corepack prepare pnpm@8.11.0 --activate
# Set up PNPM_HOME and add it to PATH
ENV PNPM_HOME=/usr/local/bin
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm install -g typescript@latest

# Set environment variables
ENV NODE_ENV=production
ENV NODE_OPTIONS="--max-old-space-size=8192"
ENV ROLLUP_SKIP_NODEJS=true

# Set up workspace
WORKDIR /app

# Copy source files first (excluding node_modules)
COPY . .

# Now copy the dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/frontend/node_modules ./frontend/node_modules

# Build the application
WORKDIR /app/frontend
# Install specific Rollup dependencies for Alpine Linux
RUN apk add --no-cache python3 make g++ curl

# Install uv for faster Python package management
RUN curl -sSf https://astral.sh/uv/install.sh | sh

# Use pre-built binaries for Rollup when possible
ENV ROLLUP_SKIP_NODEJS=true
ENV ROLLUP_NATIVE_BUILD=false

# Install Rollup with optimized settings
RUN PNPM_CACHE_FOLDER="/tmp/.pnpm-cache" pnpm install --prefer-offline --ignore-scripts @rollup/rollup-linux-x64-musl

# Install React type declarations and other required packages
RUN pnpm install --no-save @types/react @vitejs/plugin-react vite

# Create comprehensive declaration file for missing modules
RUN echo 'declare module "*.svg" { const content: string; export default content; }' > /app/frontend/src/types.d.ts && \
    echo 'declare module "react/jsx-runtime" { import * as React from "react"; export const jsx: any; export const jsxs: any; export const Fragment: React.FC; }' >> /app/frontend/src/types.d.ts

# Create a temporary tsconfig.json that skips type checking
RUN echo '{"extends": "./tsconfig.json", "compilerOptions": {"skipLibCheck": true, "noEmit": true}}' > /app/frontend/tsconfig.build.json

# Create a simplified vite.config.js file
RUN echo 'import { defineConfig } from "vite"; import react from "@vitejs/plugin-react"; export default defineConfig({ plugins: [react()], build: { outDir: "dist" } });' > /app/frontend/vite.config.js

# Install all required packages in the frontend directory, skipping husky hooks
RUN pnpm install --ignore-scripts --prefer-offline --no-optional

# Build using Vite directly with optimized settings
RUN NODE_ENV=production NODE_OPTIONS="--max-old-space-size=4096" npx vite build --emptyOutDir

# Stage 2: Development stage (used for development)
FROM --platform=linux/amd64 node:18-alpine AS development

# Install pnpm and TypeScript globally
RUN corepack enable && corepack prepare pnpm@8.11.0 --activate
# Set up PNPM_HOME and add it to PATH
ENV PNPM_HOME=/usr/local/bin
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm install -g typescript@latest

# Set environment variables
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV PNPM_CACHE_FOLDER="/app/.pnpm-cache"

# Set up workspace
WORKDIR /app

# Copy package files and install dependencies
COPY package.json pnpm-lock.yaml* ./
COPY frontend/package.json ./frontend/

# Create empty directories for mounting
RUN mkdir -p /app/frontend

# Stage 3: Production stage
FROM --platform=linux/amd64 node:18-alpine AS production

# Set environment variables
ENV NODE_ENV=production

# Set up workspace
WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/frontend/dist ./frontend/dist
COPY --from=builder /app/frontend/package.json ./frontend/

# Install pnpm and serve
RUN corepack enable && corepack prepare pnpm@8.11.0 --activate
# Set up PNPM_HOME and add it to PATH
ENV PNPM_HOME=/usr/local/bin
ENV PATH="$PNPM_HOME:$PATH"
RUN pnpm install -g serve

# Expose port
EXPOSE 5173

# Start command
CMD ["serve", "-s", "frontend/dist", "-l", "5173"]

# End of Dockerfile
