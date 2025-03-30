from sqlmodel import SQLModel

from app.core.db import engine


def create_test_db():
    """Create test database and tables."""
    # Create all tables
    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)

if __name__ == "__main__":
    create_test_db()
