#!/usr/bin/env python3
import os

import pytest
import requests


@pytest.fixture
def base_url():
    """Get base URL from environment variable or use default."""
    return os.getenv("TEST_API_URL", "http://localhost:8000")

@pytest.fixture
def test_credentials():
    """Get test credentials from environment variables or use defaults."""
    username = os.getenv("TEST_USERNAME", "admin@example.com")
    password = os.getenv("TEST_PASSWORD", "FastAPI_Secure_2025!")
    return username, password

def test_login_success(base_url, test_credentials):
    """Test successful login with valid credentials."""
    username, password = test_credentials

    form_data = {
        "username": username,
        "password": password,
        "grant_type": "password"
    }

    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.post(
        f"{base_url}/api/v1/login/access-token",
        data=form_data,
        headers=headers
    )

    assert response.status_code == 200
    assert "access_token" in response.json()
    assert "token_type" in response.json()

def test_login_failure(base_url):
    """Test login with invalid credentials."""

    form_data = {
        "username": "invalid@example.com",
        "password": "wrongpassword",
        "grant_type": "password"
    }

    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.post(
        f"{base_url}/api/v1/login/access-token",
        data=form_data,
        headers=headers
    )

    assert response.status_code == 401
