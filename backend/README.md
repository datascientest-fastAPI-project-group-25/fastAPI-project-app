# 🔥 DevOps Demo Application - Backend

![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi) ![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)

The backend of our DevOps demo application is built with FastAPI, providing a high-performance, easy-to-use API with automatic interactive documentation.

## 💻 Table of Contents

- [Features](#-features)
- [Requirements](#-requirements)
- [Development Setup](#-development-setup)
  - [Docker-based Development](#docker-based-development)
  - [Local Development](#local-development)
- [API Documentation](#-api-documentation)
- [Project Structure](#-project-structure)
- [Database](#-database)
- [Testing](#-testing)
- [Deployment](#-deployment)

## ✨ Features

- **FastAPI Framework**: High-performance, easy to learn, fast to code, ready for production
- **SQLModel ORM**: SQL databases in Python, designed for simplicity, compatibility, and robustness
- **JWT Authentication**: Secure authentication with JWT tokens
- **Automatic API Documentation**: Interactive API documentation with Swagger UI and ReDoc
- **Dependency Injection**: Clean and testable code with FastAPI's dependency injection system
- **Async Support**: Fully asynchronous API endpoints for high performance
- **Comprehensive Testing**: Pytest-based test suite with high coverage

## 📍 Requirements

- [Docker](https://www.docker.com/) and Docker Compose
- [Python](https://www.python.org/) 3.11+
- [uv](https://github.com/astral-sh/uv/) for Python package and environment management
- [PostgreSQL](https://www.postgresql.org/) (when running locally without Docker)

## 🔧 Development Setup

### Docker-based Development

The easiest way to get started is using Docker Compose, which sets up all required services including the database.

```bash
# From the project root directory
docker compose up -d
```

This will start:

- Backend API at http://api.localhost
- PostgreSQL database
- Adminer (database management) at http://adminer.localhost

### Local Development

For a more responsive development experience, you can run the backend locally.

1. **Set up environment variables**

```bash
# From the project root directory
cp .env.example .env
# Edit .env with your preferred settings
```

2. **Install dependencies**

```bash
# Navigate to backend directory
cd backend

# Create a virtual environment
uv venv

# Activate the virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
uv pip install -e .
```

3. **Start the development server**

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 📖 API Documentation

FastAPI automatically generates interactive API documentation:

- **Swagger UI**: http://localhost:8000/docs

  - Interactive documentation with request/response examples
  - Try out API endpoints directly from the browser

- **ReDoc**: http://localhost:8000/redoc
  - Alternative documentation interface
  - More readable for complex APIs

## 📂 Project Structure

```
backend/
├── app/
│   ├── api/
│   │   ├── deps.py         # Dependency injection
│   │   └── routes/         # API endpoints
│   ├── core/               # Core functionality
│   │   ├── config.py       # Configuration
│   │   └── security.py     # Security utilities
│   ├── crud/               # CRUD operations
│   ├── db/                 # Database setup
│   ├── models/             # SQLModel models
│   ├── schemas/            # Pydantic schemas
│   ├── tests/              # Tests
│   └── main.py             # Application entry point
└── pyproject.toml          # Project dependencies
```

## 💾 Database

### Migrations

The application uses Alembic for database migrations:

```bash
# Generate a new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head
```

### Database Models

Models are defined using SQLModel, which combines SQLAlchemy and Pydantic:

```python
from sqlmodel import Field, SQLModel

class User(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    email: str = Field(unique=True, index=True)
    # ...
```

## 🧪 Testing

The backend includes a comprehensive test suite using pytest:

```bash
# Run all tests
pytest

# Run tests with coverage report
pytest --cov=app

# Run specific test file
pytest app/tests/api/routes/test_users.py
```

## 🚀 Deployment

The backend is designed to be deployed as a Docker container to AWS ECS. The deployment is handled automatically by GitHub Actions when changes are pushed to the appropriate branches.

For more information on the deployment process, see the CI/CD Pipeline section in the main README.
