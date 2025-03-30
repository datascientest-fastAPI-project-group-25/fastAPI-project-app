FROM python:3.11-slim-bookworm

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install uv and add it to PATH
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    echo 'export PATH="/root/.local/bin:$PATH"' >> ~/.bashrc && \
    . ~/.bashrc && \
    ln -s /root/.local/bin/uv /usr/local/bin/uv

# Copy project files
COPY backend/pyproject.toml backend/uv.lock ./

# Install Python dependencies using uv with explicit path and set PYTHONPATH
RUN /root/.local/bin/uv pip install --system \
    sqlalchemy==2.0.23 \
    sqlmodel alembic psycopg psycopg-binary \
    fastapi tenacity && \
    /root/.local/bin/uv pip install --system -e .

# Copy application files
COPY backend /app/backend
COPY backend/app /app/backend/app
COPY backend/scripts /app/scripts

# Set up directories and permissions
RUN mkdir -p /app/backend/app/alembic/versions && \
    chmod +x /app/scripts/*

# Create alembic directory
RUN mkdir -p /app/backend/alembic/versions

# Set environment variables
ENV PYTHONPATH="/app:/app/backend" \
    BACKEND_DIR="/app/backend" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    ALEMBIC_CONFIG="/app/backend/alembic.ini"

CMD ["/app/scripts/prestart.sh"]
