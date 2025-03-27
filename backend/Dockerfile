# Stage 1: Build the environment with uv
FROM python:3.11-slim-bookworm as builder

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONBREAKSYSTEMPACKAGES=1

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install uv
RUN pip install uv

# Set the working directory
WORKDIR /app

# Copy dependency files
COPY pyproject.toml uv.lock alembic.ini ./

# Create virtual environment and install dependencies
RUN uv venv /app/.venv && \
    . /app/.venv/bin/activate && \
    uv pip install -e ".[dev,lint,types,test]" && \
    uv pip install sqlalchemy sqlmodel psycopg[binary] alembic tenacity "fastapi[standard]" pydantic pydantic-settings emails jinja2 httpx PyJWT passlib python-multipart bcrypt email-validator sentry-sdk

# Stage 2: Development environment
FROM python:3.11-slim-bookworm as development

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONBREAKSYSTEMPACKAGES=1 \
    PYTHONPATH=/app \
    PATH="/app/.venv/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy uv from builder
COPY --from=builder /usr/local/bin/uv /usr/local/bin/uv

# Copy application code
COPY pyproject.toml uv.lock alembic.ini ./
COPY app/ ./app/
COPY scripts/ ./scripts/

# Make scripts executable
RUN chmod +x /app/scripts/*

# Stage 3: Test environment
FROM development as test

# Install additional test dependencies
RUN . /app/.venv/bin/activate && \
    uv pip install pytest-cov pytest-asyncio httpx

# Stage 4: Production environment
FROM python:3.11-slim-bookworm as production

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONBREAKSYSTEMPACKAGES=1 \
    PYTHONPATH=/app \
    PATH="/app/.venv/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY pyproject.toml uv.lock alembic.ini ./
