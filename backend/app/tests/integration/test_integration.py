import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session

from app import crud
from app.core.config import settings
from app.models import UserCreate
from app.tests.utils.utils import random_email, random_lower_string


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
    test_user_db = crud.user.create(db, obj_in=test_user)
    superuser_db = crud.user.create(db, obj_in=superuser)

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
def test_complete_user_flow(client: TestClient, test_data):
    # Test user creation
    new_user = UserCreate(email=random_email(), password=random_lower_string())

    response = client.post(
        f"{settings.API_V1_STR}/users/",
        headers={"Authorization": f"Bearer {test_data['superuser_token']}"},
        json=new_user.dict(),
    )
    assert response.status_code == 200
    created_user = response.json()
    assert created_user["email"] == new_user.email

    # Test login
    login_data = {"username": new_user.email, "password": new_user.password}

    response = client.post(f"{settings.API_V1_STR}/login/access-token", data=login_data)
    assert response.status_code == 200
    token = response.json()["access_token"]

    # Test user retrieval
    response = client.get(
        f"{settings.API_V1_STR}/users/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    current_user = response.json()
    assert current_user["email"] == new_user.email

    # Test user update
    update_data = {"email": random_email(), "password": random_lower_string()}

    response = client.put(
        f"{settings.API_V1_STR}/users/me",
        headers={"Authorization": f"Bearer {token}"},
        json=update_data,
    )
    assert response.status_code == 200
    updated_user = response.json()
    assert updated_user["email"] == update_data["email"]

    # Test password update
    password_data = {
        "current_password": new_user.password,
        "new_password": random_lower_string(),
    }

    response = client.put(
        f"{settings.API_V1_STR}/users/me/password",
        headers={"Authorization": f"Bearer {token}"},
        json=password_data,
    )
    assert response.status_code == 200

    # Test user deletion
    response = client.delete(
        f"{settings.API_V1_STR}/users/me", headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200


@pytest.mark.integration
@pytest.mark.parametrize(
    "endpoint,method",
    [
        ("/users/me", "GET"),
        ("/users/me", "PUT"),
        ("/users/me/password", "PUT"),
        ("/users/me", "DELETE"),
    ],
)
def test_endpoints_with_invalid_token(client: TestClient, endpoint: str, method: str):
    headers = {"Authorization": "Bearer invalid_token"}

    if method == "GET":
        response = client.get(endpoint, headers=headers)
    elif method == "PUT":
        response = client.put(endpoint, headers=headers, json={})
    elif method == "DELETE":
        response = client.delete(endpoint, headers=headers)

    assert response.status_code == 401
