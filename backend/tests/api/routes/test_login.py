from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlmodel import Session

from app.core.config import settings
from app.core.security import verify_password
from app.crud import create_user
from app.schemas import UserCreate
from app.utils import generate_password_reset_token
from tests.utils.utils import random_email, random_lower_string


@pytest.mark.api
def test_get_access_token(client: TestClient) -> None:
    login_data = {
        "username": settings.FIRST_SUPERUSER,
        "password": settings.FIRST_SUPERUSER_PASSWORD,
    }
    r = client.post(f"{settings.API_V1_STR}/login/access-token", data=login_data)
    tokens = r.json()
    assert r.status_code == 200
    assert "access_token" in tokens
    assert tokens["access_token"]


@pytest.mark.api
def test_get_access_token_incorrect_password(client: TestClient) -> None:
    login_data = {
        "username": settings.FIRST_SUPERUSER,
        "password": "incorrect_password",
    }
    r = client.post(f"{settings.API_V1_STR}/login/access-token", data=login_data)
    assert r.status_code == 400


@pytest.mark.api
def test_use_access_token(
    client: TestClient, superuser_token_headers: dict[str, str]
) -> None:
    r = client.post(
        f"{settings.API_V1_STR}/login/test-token",
        headers=superuser_token_headers,
    )
    result = r.json()
    assert r.status_code == 200
    assert "email" in result


@pytest.mark.api
def test_recovery_password(client: TestClient) -> None:
    with patch("app.api.routes.login.send_email") as mock_send_email:
        email = settings.EMAIL_TEST_USER
        r = client.post(
            f"{settings.API_V1_STR}/password-recovery/{email}",
        )
        assert r.status_code == 200
        mock_send_email.assert_called_once()
        assert r.json() == {"msg": "Password recovery email sent"}


@pytest.mark.api
def test_recovery_password_user_not_exists(
    client: TestClient,
) -> None:
    email = "nonexistentuser@example.com"
    r = client.post(
        f"{settings.API_V1_STR}/password-recovery/{email}",
    )
    assert r.status_code == 404


@pytest.mark.api
def test_reset_password(client: TestClient, db: Session) -> None:
    email = random_email()
    password = random_lower_string()  # Removed length parameter
    new_password = random_lower_string()  # Removed length parameter

    user_create = UserCreate(
        email=email,
        full_name="Test User Reset",
        password=password,
        is_active=True,
        is_superuser=False,
    )
    user = create_user(session=db, user_create=user_create)
    token = generate_password_reset_token(email=email)
    data = {"new_password": new_password, "token": token}

    r = client.post(
        f"{settings.API_V1_STR}/reset-password/",
        json=data,
    )

    assert r.status_code == 200
    assert r.json() == {"message": "Password updated successfully"}

    db.refresh(user)
    assert verify_password(new_password, user.hashed_password)


@pytest.mark.api
def test_reset_password_invalid_token(
    client: TestClient,
) -> None:
    data = {"new_password": "changethispassword", "token": "invalid_token"}
    r = client.post(
        f"{settings.API_V1_STR}/reset-password/",
        json=data,
    )
    response = r.json()

    assert "detail" in response
    assert r.status_code == 400
    assert response["detail"] == "Invalid token"
