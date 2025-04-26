# syntax=docker/dockerfile:1

# --- Base Stage --- #
FROM python:3.11-slim-bookworm as base

# Accept build arguments for versioning
ARG GIT_HASH="unknown"
ARG BRANCH_TYPE="local"
ENV GIT_HASH=${GIT_HASH} \
    BRANCH_TYPE=${BRANCH_TYPE}

# Set base environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH="/app" \
    APP_HOME="/app"
WORKDIR $APP_HOME

# Create a non-root user and group
RUN groupadd --system --gid 1001 appuser && \
    useradd --system --uid 1001 --gid appuser --home-dir $APP_HOME --no-create-home appuser

# --- Builder Stage --- #
FROM base as builder

# Install system build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:0.4.15 /uv /usr/local/bin/

# Copy dependency definition files
# When using backend directory as context, these files should be at the root
COPY pyproject.toml ./ # Copy to current WORKDIR ($APP_HOME)
# COPY ./uv.lock ./       # Remove if not needed, uncomment if exists

# Build the virtual environment
RUN uv pip sync --system uv.lock

# Copy application code
# When using backend directory as context, this copies everything from the backend dir
COPY . .

# Make scripts executable (adjust path if needed)
RUN chmod +x ./scripts/*.sh

# Ensure ownership is correct for builder stage (optional but good practice)
RUN chown -R appuser:appuser $APP_HOME

# --- Final Stage --- #
FROM base as final

# Install runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Copy installed Python environment from builder
COPY --from=builder /usr/local /usr/local

# Copy application code from builder
COPY --from=builder --chown=appuser:appuser $APP_HOME $APP_HOME

# Switch to the non-root user
USER appuser

# Define the command to run the application
CMD ["./scripts/prestart.sh"]
