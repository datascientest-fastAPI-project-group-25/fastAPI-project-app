# DevOps Demo Application - Backend

## Requirements

* [Docker](https://www.docker.com/).
* [uv](https://github.com/astral-sh/uv/) for Python package and environment management.

## Docker Compose

Start the local development environment with Docker Compose by running `docker compose up -d` from the root directory.

## General Workflow

By default, the dependencies are managed with [uv](https://github.com/astral-sh/uv/), go there and install it.

From `./backend/` you can install all the dependencies with:

```bash
# Create a virtual environment
uv venv

# Activate the virtual environment
source .venv/bin/activate

# Install dependencies
uv pip install -e .
```

## Development

Start the development server with:

```bash
uvicorn app.main:app --reload
```

The API will be available at http://localhost:8000/api/v1/

API documentation is available at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
