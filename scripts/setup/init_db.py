#!/usr/bin/env python3

import os
import sys
import logging
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def get_database_url():
    """Get database URL from environment variables."""
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        logger.error("DATABASE_URL environment variable not set")
        sys.exit(1)
    return db_url


def create_database(engine):
    """Create database and required schemas."""
    try:
        # Create extensions
        with engine.connect() as conn:
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
            conn.execute(text("CREATE EXTENSION IF NOT EXISTS unaccent"))
            conn.commit()
            logger.info("Database extensions created successfully")

        # Create schemas
        with engine.connect() as conn:
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS public"))
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS auth"))
            conn.execute(text("CREATE SCHEMA IF NOT EXISTS api"))
            conn.commit()
            logger.info("Database schemas created successfully")

        return True

    except SQLAlchemyError as e:
        logger.error(f"Error creating database: {e}")
        return False


def create_test_database(engine):
    """Create test database."""
    try:
        test_db_name = "test_db"
        with engine.connect() as conn:
            # Drop test database if it exists
            conn.execute(text(f"DROP DATABASE IF EXISTS {test_db_name}"))
            # Create test database
            conn.execute(text(f"CREATE DATABASE {test_db_name}"))
            conn.commit()
            logger.info("Test database created successfully")

        return True

    except SQLAlchemyError as e:
        logger.error(f"Error creating test database: {e}")
        return False


def main():
    """Main function to initialize the database."""
    try:
        # Get database URL
        db_url = get_database_url()
        logger.info("Connecting to database...")

        # Create SQLAlchemy engine
        engine = create_engine(db_url)

        # Create database and schemas
        if not create_database(engine):
            logger.error("Failed to create database and schemas")
            sys.exit(1)

        # Create test database
        if not create_test_database(engine):
            logger.error("Failed to create test database")
            sys.exit(1)

        logger.info("Database initialization completed successfully!")
        sys.exit(0)

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
