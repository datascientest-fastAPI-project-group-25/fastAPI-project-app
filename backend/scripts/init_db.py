#!/usr/bin/env python3
"""
Database initialization script for CI/CD pipelines.
This script creates all database tables and initializes the database with test data.

Note: This script requires all backend dependencies to be installed.
If running locally, make sure to install dependencies with:
    cd backend && pip install -r requirements.txt
"""

import os
import sys

# Add the parent directory to the Python path to make 'app' importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from app.core.db import init_db, engine
    from sqlmodel import Session
    from app.models import Base  # This imports the SQLAlchemy models
except ImportError as e:
    print(f"Error importing required modules: {e}")
    print("Make sure all dependencies are installed with: pip install -r requirements.txt")
    sys.exit(1)


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
