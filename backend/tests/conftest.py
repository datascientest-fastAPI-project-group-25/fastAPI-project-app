from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel

from app.core.config import settings
from app.core.db import engine, init_db
from app.main import app
from tests.utils.user import authentication_token_from_email
from tests.utils.utils import get_superuser_token_headers


@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Create test database and tables."""
    # Create all tables
    SQLModel.metadata.drop_all(engine)
    SQLModel.metadata.create_all(engine)
    yield
    # Clean up after tests
    SQLModel.metadata.drop_all(engine)

@pytest.fixture(scope="function")
def db() -> Generator[Session, None, None]:
    """Return a database session for each test."""
    with Session(engine) as session:
        yield session
        # Clean up after each test
        session.rollback()
        session.close()

@pytest.fixture(scope="function")
def client(db: Session) -> Generator[TestClient, None, None]:
    """Create a new test client with fresh database session."""
    with TestClient(app) as c:
        init_db(db)  # Initialize database with superuser
        yield c

@pytest.fixture(scope="function")
def superuser_token_headers(client: TestClient) -> dict[str, str]:
    """Get superuser token headers."""
    return get_superuser_token_headers(client)

@pytest.fixture(scope="function")
def normal_user_token_headers(client: TestClient, db: Session) -> dict[str, str]:
    """Get normal user token headers."""
    return authentication_token_from_email(
        client=client, email=settings.EMAIL_TEST_USER, db=db
    )
