#!/usr/bin/env python3

import os
import sys
import logging
from typing import Dict, List, Optional
from pydantic import BaseModel, EmailStr, SecretStr, ValidationError
from pydantic_settings import BaseSettings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class Settings(BaseSettings):
    """Application settings model."""

    # Application
    APP_NAME: str
    APP_VERSION: str
    ENVIRONMENT: str

    # Security
    SECRET_KEY: SecretStr
    DEBUG: bool

    # Database
    POSTGRES_SERVER: str
    POSTGRES_USER: str
    POSTGRES_PASSWORD: SecretStr
    POSTGRES_DB: str
    POSTGRES_PORT: int

    # Admin User
    FIRST_SUPERUSER: EmailStr
    FIRST_SUPERUSER_PASSWORD: SecretStr

    # API Configuration
    API_V1_STR: str
    BACKEND_CORS_ORIGINS: List[str]

    # JWT Configuration
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_EXPIRE_DAYS: int

    # Docker Registry
    DOCKER_REGISTRY: str
    DOCKER_REPOSITORY: str

    # Monitoring
    ENABLE_METRICS: bool
    METRICS_PORT: int

    # Logging
    LOG_LEVEL: str
    ENABLE_ACCESS_LOG: bool

    # Testing
    TEST_DATABASE_URL: Optional[str] = None

    # Documentation
    ENABLE_DOCS: bool
    DOCS_URL: str
    REDOC_URL: str

    # Frontend
    NEXT_PUBLIC_API_URL: str
    NEXT_PUBLIC_APP_URL: str


def validate_environment() -> bool:
    """Validate environment variables."""
    try:
        # Load and validate settings
        settings = Settings()
        logger.info("Environment validation successful!")

        # Additional checks
        if settings.ENVIRONMENT not in ["development", "staging", "production", "test"]:
            logger.error(f"Invalid ENVIRONMENT value: {settings.ENVIRONMENT}")
            return False

        if settings.LOG_LEVEL not in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
            logger.error(f"Invalid LOG_LEVEL value: {settings.LOG_LEVEL}")
            return False

        # Check database connection string format
        if settings.TEST_DATABASE_URL:
            if not settings.TEST_DATABASE_URL.startswith("postgresql://"):
                logger.error("TEST_DATABASE_URL must start with postgresql://")
                return False

        # Check CORS origins format
        for origin in settings.BACKEND_CORS_ORIGINS:
            if not origin.startswith(("http://", "https://")):
                logger.error(f"Invalid CORS origin format: {origin}")
                return False

        return True

    except ValidationError as e:
        logger.error("Environment validation failed!")
        for error in e.errors():
            logger.error(f"- {error['loc'][0]}: {error['msg']}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error during validation: {e}")
        return False


if __name__ == "__main__":
    if not validate_environment():
        sys.exit(1)
    sys.exit(0)
