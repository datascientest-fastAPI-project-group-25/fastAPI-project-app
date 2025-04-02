import pytest
from fastapi.testclient import TestClient

from app.core.config import settings


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
def test_recovery_password_user_not_exists(
    client: TestClient,
) -> None:
    email = "nonexistentuser@example.com"
    r = client.post(
        f"{settings.API_V1_STR}/login/password-recovery/{email}",
    )
    assert r.status_code == 404
