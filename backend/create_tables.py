
from app.core.db import engine
from app.models import SQLModel


def create_tables():
    print("Creating database tables...")
    SQLModel.metadata.create_all(engine)
    print("Database tables created.")

if __name__ == "__main__":
    create_tables()
