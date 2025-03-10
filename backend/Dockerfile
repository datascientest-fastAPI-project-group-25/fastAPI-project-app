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

COPY --from=ghcr.io/astral-sh/uv:0.5.11 /uv /uvx /bin/

# Development stage with all dependencies
FROM base as development

# Copy dependency files and project structure
COPY pyproject.toml uv.lock alembic.ini ./
COPY app/ ./app/
COPY scripts/ ./scripts/

# Install all dependencies including dev dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv && \
    uv sync

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
COPY app/ ./app/
COPY scripts/ ./scripts/

# Install only production dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    uv venv && \
    uv pip compile pyproject.toml --output-file requirements.txt && \
    uv pip install --system -r requirements.txt && \
    rm requirements.txt

# Make scripts executable
RUN chmod +x /app/scripts/*

# Default command
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "4"]
