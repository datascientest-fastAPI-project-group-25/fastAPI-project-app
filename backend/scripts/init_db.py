#!/usr/bin/env python3
"""
Database initialization script for CI/CD pipelines.
This script creates all database tables and initializes the database with test data.
"""

from app.db.init_db import init_db
from app.db.session import Session, engine
from app.db.base import Base


def initialize_database():
    """Create all database tables and initialize with test data."""
    print("Creating database tables...")
    Base.metadata.create_all(bind=engine)
    
    print("Initializing database with test data...")
    session = Session()
    try:
        init_db(session)
        print("Database initialization completed successfully.")
    finally:
        session.close()


if __name__ == "__main__":
    initialize_database()
