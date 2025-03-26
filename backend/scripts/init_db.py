#!/usr/bin/env python3
"""
Database initialization script for CI/CD pipelines.
This script creates all database tables and initializes the database with
test data.

Note: This script requires all backend dependencies to be installed.
If running locally, make sure to install dependencies with:
    cd backend && pip install -r requirements.txt
"""

import logging
import os
import sys
import traceback

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("db_init")

# Add the parent directory to the Python path to make 'app' importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    logger.info("Importing required modules...")
    from sqlmodel import Session, SQLModel

    from app.core.db import engine, init_db

    # SQLModel is used instead of Base for table creation
    logger.info("Successfully imported all required modules")
except ImportError as e:
    logger.error(f"Error importing required modules: {e}")
    logger.error(
        "Make sure all dependencies are installed with: pip install -r requirements.txt"
    )
    logger.error(traceback.format_exc())
    sys.exit(1)


def initialize_database():
    """Create all database tables and initialize with test data."""
    try:
        logger.info("Starting database table creation process...")
        # Log the engine connection information (without sensitive details)
        logger.info(f"Using database engine: {engine.name}")
        logger.info("Creating database tables...")
        SQLModel.metadata.create_all(bind=engine)
        logger.info("Database tables created successfully")
    except Exception as e:
        logger.error(f"Failed to create database tables: {e}")
        logger.error(traceback.format_exc())
        sys.exit(1)

    session = None
    try:
        logger.info("Initializing database with test data...")
        # Get connection timeout from environment variable or use default
        connection_timeout = int(os.getenv("DB_CONNECTION_TIMEOUT", "10"))
        logger.info(f"Using database connection timeout: {connection_timeout} seconds")
        # Create session with connection timeout for more robust database connections
        session = Session(
            bind=engine.execution_options(
                connect_args={"connect_timeout": connection_timeout}
            )
        )
        init_db(session)
        session.commit()  # Commit the changes
        logger.info("Database initialization completed successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database with test data: {e}")
        logger.error(traceback.format_exc())
        if session:
            logger.warning("Rolling back database changes due to error")
            session.rollback()  # Rollback in case of error
        sys.exit(1)
    finally:
        if session:
            logger.info("Closing database session")
            session.close()


if __name__ == "__main__":
    initialize_database()
