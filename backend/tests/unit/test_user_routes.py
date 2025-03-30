import uuid
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient

from app.models import User


@pytest.mark.unit
def test_create_user_api(client: TestClient, superuser_token_headers: dict[str, str]):
    """Test user creation API endpoint with mocked database operations."""
    # Setup with all required fields matching UserCreate schema exactly
    user_data = {
        "email": "test@example.com",
        "password": "testpassword123",
        "full_name": "Test User",
    }

    # Mock the create_user function and get_user_by_email
    mock_user = User(
        id=uuid.uuid4(),
        email=user_data["email"],
        hashed_password="hashed_password",
        is_active=True,
        is_superuser=False,
        full_name=user_data["full_name"]
    )

    # Execute with patched crud functions
    with patch("app.api.routes.users.crud.get_user_by_email", return_value=None), \
         patch("app.api.routes.users.crud.create_user", return_value=mock_user):
        response = client.post(
            "/api/v1/users/",
            headers=superuser_token_headers,
            json=user_data,
        )

    # Assert
    assert response.status_code == 200
    assert response.json()["email"] == user_data["email"]
    assert response.json()["full_name"] == user_data["full_name"]

@pytest.mark.unit
def test_get_users_api(client: TestClient, superuser_token_headers: dict[str, str]):
    """Test get users API endpoint with mocked database operations."""
    # Setup - Mock the get_users function with exactly 2 users
    mock_users = [
        User(
            id=uuid.uuid4(),
            email="user1@example.com",
            hashed_password="hashed1",
            is_active=True,
            is_superuser=False,
            full_name="User One"
        ),
        User(
            id=uuid.uuid4(),
            email="user2@example.com",
            hashed_password="hashed2",
            is_active=True,
            is_superuser=False,
            full_name="User Two"
        )
    ]

    # Mock both the count and user list queries
    with patch("app.api.routes.users.crud.get_users", return_value=mock_users), \
         patch("app.api.routes.users.crud.count_users", return_value=2):
        response = client.get(
            "/api/v1/users/",
            headers=superuser_token_headers,
        )

    # Assert
    assert response.status_code == 200
    data = response.json()
    assert data["count"] == 2
    assert len(data["data"]) == 2
    assert data["data"][0]["email"] == "user1@example.com"
    assert data["data"][1]["email"] == "user2@example.com"
