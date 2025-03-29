from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.api.deps import get_db
from app.main import app
from app.models.user import User


@pytest.fixture
def client():
    """Create a test client with mocked database session."""

    def override_get_db():
        mock_db = MagicMock(spec=Session)
        try:
            yield mock_db
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides = {}


def test_create_user_api(client):
    """Test user creation API endpoint with mocked database operations."""
    # Setup
    user_data = {"email": "test@example.com", "password": "testpassword"}

    # Mock the create_user function
    mock_user = User(
        id=1,
        email=user_data["email"],
        hashed_password="hashed_password",
        is_active=True,
        is_superuser=False,
    )

    # Execute with patched crud function
    with patch("app.api.routes.users.crud.create_user", return_value=mock_user):
        response = client.post("/api/v1/users/", json=user_data)

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == user_data["email"]
    assert "id" in data
    assert "password" not in data


def test_get_users_api(client):
    """Test get users API endpoint with mocked database operations."""
    # Setup - Mock the get_users function
    mock_users = [
        User(
            id=1,
            email="user1@example.com",
            hashed_password="hashed1",
            is_active=True,
            is_superuser=False,
        ),
        User(
            id=2,
            email="user2@example.com",
            hashed_password="hashed2",
            is_active=True,
            is_superuser=False,
        ),
    ]

    # Execute with patched crud function
    with patch("app.api.routes.users.crud.get_users", return_value=mock_users):
        response = client.get("/api/v1/users/")

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["email"] == "user1@example.com"
    assert data[1]["email"] == "user2@example.com"
