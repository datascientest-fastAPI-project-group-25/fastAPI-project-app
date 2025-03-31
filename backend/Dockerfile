FROM python:3.11-slim-bookworm as development

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    procps \
    postgresql-client \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy uv from the official image (best practice according to docs)
COPY --from=ghcr.io/astral-sh/uv:0.4.15 /uv /uvx /bin/

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    PYTHONPATH="/app/backend" \
    BACKEND_DIR="/app/backend"

# Create backend directory structure
RUN mkdir -p /app/backend/app /app/backend/alembic/versions /app/backend/tests

# Copy the application files
COPY backend/ /app/backend/

# Make scripts executable
RUN chmod +x /app/backend/scripts/*.sh

# Install dependencies with uv using pyproject.toml
WORKDIR /app/backend
RUN uv pip install --system -e .

# Install additional dependencies explicitly
RUN uv pip install --system psycopg2-binary python-jose passlib python-multipart email-validator

CMD ["/app/backend/scripts/prestart.sh"]
