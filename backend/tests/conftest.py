import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session, SQLModel
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.core.db import init_db
from app.main import app
from app.db.base import Base
from app.api.deps import get_db
from app.utils import get_password_hash
from tests.utils.test_db import test_engine as engine
from tests.utils.user import authentication_token_from_email
from tests.utils.utils import get_superuser_token_headers

# Override database settings for tests
os.environ["POSTGRES_SERVER"] = ""
os.environ["POSTGRES_USER"] = ""
os.environ["POSTGRES_PASSWORD"] = ""
os.environ["POSTGRES_DB"] = ""
os.environ["SQLALCHEMY_DATABASE_URI"] = "sqlite:///./test.db"

@pytest.fixture(scope="session", autouse=True)
def setup_test_db():
    """Create test database and tables."""
    from tests.utils.test_db import create_test_tables
    create_test_tables()
    with Session(engine) as session:
        init_db(session)  # Create initial superuser
        session.commit()
    yield
    SQLModel.metadata.drop_all(engine)
    engine.dispose()

@pytest.fixture(scope="function")
def db() -> Generator[Session, None, None]:
    """Return a database session for each test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = Session(bind=connection)

    try:
        yield session
    finally:
        session.rollback()
        transaction.rollback()
        session.close()
        connection.close()

@pytest.fixture
def client(db: Session) -> TestClient:
    """Create a new test client with fresh database session."""
    def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c

@pytest.fixture
def superuser_token_headers(client: TestClient) -> dict[str, str]:
    """Get superuser token headers."""
    return get_superuser_token_headers(client)

@pytest.fixture
def normal_user_token_headers(client: TestClient, db: Session) -> dict[str, str]:
    """Get normal user token headers."""
    return authentication_token_from_email(
        client=client, email=settings.EMAIL_TEST_USER, db=db
    )
