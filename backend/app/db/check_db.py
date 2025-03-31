#!/usr/bin/env python3
"""
Simple database connection check script.
Used by the Makefile to determine if database initialization is needed.
"""
import sys
import traceback

from sqlalchemy import create_engine, inspect, text

from app.core.config import settings


def check_database_initialized():
    """
    Check if the database is properly initialized by attempting to connect
    and verify if the user table exists with at least one record.

    Returns:
        bool: True if database is initialized, False otherwise
    """
    try:
        # Create engine with a timeout
        engine = create_engine(settings.SQLALCHEMY_DATABASE_URI, connect_args={"connect_timeout": 5})

        # Try to connect
        with engine.connect() as conn:
            # First check if the user table exists
            inspector = inspect(engine)
            if 'user' not in inspector.get_table_names():
                print("User table does not exist")
                return False

            # Then check if there's at least one user
            result = conn.execute(text("SELECT COUNT(*) FROM \"user\""))
            user_count = result.scalar()

            if user_count == 0:
                print("No users found in database")
                return False

            print(f"Database check successful: {user_count} users found")
            return True
    except Exception as e:
        print(f"Database check failed: {str(e)}")
        traceback.print_exc()
        return False

if __name__ == "__main__":
    # Exit with code 0 if database is initialized, 1 otherwise
    initialized = check_database_initialized()
    sys.exit(0 if initialized else 1)
