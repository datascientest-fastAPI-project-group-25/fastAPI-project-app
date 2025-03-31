from collections.abc import Generator

from sqlmodel import Session, SQLModel, create_engine

# Create an in-memory SQLite database for tests
TEST_SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

# Create test engine with SQLite
test_engine = create_engine(
    TEST_SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    echo=False,
)


# Create tables only once
def create_test_tables():
    """Create all tables in the test database."""
    SQLModel.metadata.drop_all(test_engine)
    SQLModel.metadata.create_all(test_engine)


def get_test_db() -> Generator[Session, None, None]:
    """Get a test database session."""
    session = Session(test_engine)
    try:
        yield session
    finally:
        session.close()


def init_test_db() -> None:
    """Initialize the test database."""
    SQLModel.metadata.create_all(test_engine)
