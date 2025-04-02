import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.config import settings
from app.schemas import UserCreate
from tests.utils.utils import random_email, random_lower_string


@pytest.fixture(scope="module")
def test_data(client: TestClient, db: Session):
    # Create test users
    test_user = UserCreate(
        email=random_email(), password=random_lower_string(), is_superuser=False
    )

    superuser = UserCreate(
        email="superuser@example.com", password="superuser", is_superuser=True
    )

    # Create users in database
    from app import crud

    test_user_db = crud.create_user(session=db, user_create=test_user)
    superuser_db = crud.create_user(session=db, user_create=superuser)

    # Get tokens
    test_user_token = client.post(
        f"{settings.API_V1_STR}/login/access-token",
        data={"username": test_user.email, "password": test_user.password},
    ).json()["access_token"]

    superuser_token = client.post(
        f"{settings.API_V1_STR}/login/access-token",
        data={"username": superuser.email, "password": superuser.password},
    ).json()["access_token"]

    return {
        "test_user": test_user_db,
        "superuser": superuser_db,
        "test_user_token": test_user_token,
        "superuser_token": superuser_token,
    }


@pytest.mark.integration
def test_complete_user_flow(client: TestClient):
    """Test complete user flow."""
    # Create user
    user_data = {
        "email": "test@example.com",
        "password": "password123",
        "full_name": "Test User",
    }
    response = client.post("/api/v1/users/open", json=user_data)
    assert response.status_code == 200
    user = response.json()
    assert user["email"] == user_data["email"]

    # Login
    login_data = {
        "username": user_data["email"],
        "password": user_data["password"],
    }
    response = client.post("/api/v1/login/access-token", data=login_data)
    assert response.status_code == 200
    tokens = response.json()
    assert "access_token" in tokens

    # Get user
    response = client.get(
        "/api/v1/users/me",
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert response.status_code == 200
    user = response.json()
    assert user["email"] == user_data["email"]


@pytest.mark.integration
@pytest.mark.parametrize(
    "endpoint,method",
    [
        (f"{settings.API_V1_STR}/users/me", "GET"),
        (f"{settings.API_V1_STR}/users/me", "PUT"),
        (f"{settings.API_V1_STR}/users/me/password", "PUT"),
        (f"{settings.API_V1_STR}/users/me", "DELETE"),
    ],
)
def test_endpoints_with_invalid_token(
    client: TestClient, endpoint: str, method: str
):
    """Test endpoints with invalid token."""
    invalid_token = "invalid-token"
    headers = {"Authorization": f"Bearer {invalid_token}"}

    if method == "GET":
        response = client.get(endpoint, headers=headers)
    elif method == "POST":
        response = client.post(endpoint, headers=headers)
    elif method == "PUT":
        response = client.put(endpoint, headers=headers)
    elif method == "DELETE":
        response = client.delete(endpoint, headers=headers)
    else:
        raise ValueError(f"Unsupported method: {method}")

    assert response.status_code == 401
    assert response.json()["detail"] == "Could not validate credentials"
