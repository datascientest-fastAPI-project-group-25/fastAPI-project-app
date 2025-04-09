# syntax=docker/dockerfile:1

# --- Base Stage (Common Setup) ---
FROM --platform=linux/amd64 node:18-alpine AS base

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Set up pnpm global bin directory
ENV PNPM_HOME=/usr/local/bin \
    PATH="/usr/local/bin:$PATH"

WORKDIR /app

# --- Builder Stage ---
FROM base AS builder

# Copy only package.json first to leverage Docker cache
COPY package.json ./

# Install ALL dependencies (including devDependencies needed for build)
RUN pnpm install

# Copy the rest of the frontend source code
COPY . .

# Build the frontend application
RUN pnpm run build

# --- Final/Production Stage ---
FROM base AS final

WORKDIR /app

# Set NODE_ENV for production
ENV NODE_ENV=production

# Install 'serve' globally for serving static files
RUN pnpm install -g serve

# Copy built artifacts from the builder stage
# Ensure the source path in the builder stage is correct (/app/dist)
COPY --from=builder /app/dist ./dist/

# Expose the port the app runs on
EXPOSE 5173

# Command to run the application using serve
# Serve the 'dist' directory from the current working directory (/app)
CMD ["serve", "-s", "dist", "-l", "5173"]
