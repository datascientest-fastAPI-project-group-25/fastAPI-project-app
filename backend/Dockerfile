# Base stage for shared configuration
FROM python:3.11-slim as base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app \
    PATH="/app/.venv/bin:$PATH" \
    UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app/

# Install system dependencies and uv
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:0.4.15 /uv /uvx /bin/

# Development stage with all dependencies
FROM base as development

# Copy dependency files and project structure
COPY pyproject.toml uv.lock alembic.ini ./
COPY app/ ./app/
COPY scripts/ ./scripts/

# Install all dependencies including dev dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv && \
    . .venv/bin/activate && \
    uv pip install --system -e .[dev,lint,types,test] && \
    uv pip install sqlalchemy sqlmodel psycopg[binary] alembic tenacity "fastapi[standard]" pydantic pydantic-settings emails jinja2 httpx PyJWT passlib python-multipart bcrypt email-validator sentry-sdk

# Make scripts executable
RUN chmod +x /app/scripts/*

# Test stage inherits from development
FROM development as test

# Install additional test dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install pytest-cov pytest-asyncio httpx

# Production stage with minimal dependencies
FROM base as production

# Copy dependency files and project structure
COPY pyproject.toml uv.lock alembic.ini ./
