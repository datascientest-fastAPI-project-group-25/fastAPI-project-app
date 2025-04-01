#!/usr/bin/env python3
import os

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def test_credentials():
    """Get test credentials from environment variables or use defaults."""
    from app.core.config import settings
    username = os.getenv("TEST_USERNAME", settings.FIRST_SUPERUSER)
    password = os.getenv("TEST_PASSWORD", settings.FIRST_SUPERUSER_PASSWORD)
    return username, password


def test_login_success(client: TestClient, test_credentials):
    """Test successful login with valid credentials."""
    username, password = test_credentials

    response = client.post(
        "/api/v1/login/access-token",
        data={"username": username, "password": password},
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )

    assert response.status_code == 200
    assert "access_token" in response.json()
    assert "token_type" in response.json()


def test_login_failure(client: TestClient):
    """Test login with invalid credentials."""

    response = client.post(
        "/api/v1/login/access-token",
        data={"username": "invalid@example.com", "password": "wrongpassword"},
        headers={"Content-Type": "application/x-www-form-urlencoded"}
    )

    assert response.status_code == 400
