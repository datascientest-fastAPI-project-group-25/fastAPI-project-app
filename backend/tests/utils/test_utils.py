from unittest.mock import patch

import pytest
from emails.template import JinjaTemplate
from fastapi import HTTPException

from app.core.config import settings
from app.utils import (
    generate_new_account_email,
    generate_password_reset_token,
    send_reset_password_email,
    verify_password_reset_token,
)


# Mock settings for tests
def mock_settings():
    settings.SECRET_KEY = "test-secret-key"
    settings.EMAIL_RESET_TOKEN_EXPIRE_HOURS = 1
    settings.PROJECT_NAME = "Test Project"
    settings.EMAILS_FROM_EMAIL = "test@example.com"
    settings.EMAILS_FROM_NAME = "Test Project"
    settings.SERVER_HOST = "http://localhost:8000"


@pytest.fixture(autouse=True)
def setup_settings():
    mock_settings()


@patch("app.utils.send_email")
def test_generate_password_reset_token(_mock_send_email):
    """Test generating a password reset token."""
    email = "test@example.com"
    token = generate_password_reset_token(email)
    assert isinstance(token, str)
    assert len(token) > 0


@patch("app.utils.send_email")
def test_verify_password_reset_token(_mock_send_email):
    """Test verifying a password reset token."""
    email = "test@example.com"
    token = generate_password_reset_token(email)
    verified_email = verify_password_reset_token(token)
    assert verified_email == email

    # Test with invalid token
    invalid_token = "invalid-token"
    with pytest.raises(HTTPException):
        verify_password_reset_token(invalid_token)

    # Test with expired token
    expired_token = generate_password_reset_token(email, expires_delta=-1)
    with pytest.raises(HTTPException):
        verify_password_reset_token(expired_token)

    # Test with tampered token
    tampered_token = token + "tampered"
    with pytest.raises(HTTPException):
        verify_password_reset_token(tampered_token)


@patch("app.utils.send_email")
def test_generate_new_account_email(mock_send_email):
    email = "test@example.com"
    generate_new_account_email(email)

    mock_send_email.assert_called_once()
    call_args = mock_send_email.call_args[1]

    assert call_args["email_to"] == email
    assert "Welcome to Test Project" in call_args["subject"]

    # Test that environment variables are passed correctly
    env = call_args["environment"]
    assert env["project_name"] == settings.PROJECT_NAME
    assert env["email"] == email

    # Create a JinjaTemplate and render it to verify template variables
    template = JinjaTemplate(call_args["html_content"])
    rendered = template.render(**env)

    assert "{{ project_name }}" not in rendered
    assert "{{ email }}" not in rendered
    assert settings.PROJECT_NAME in rendered
    assert email in rendered


@patch("app.utils.send_email")
def test_send_reset_password_email(mock_send_email):
    email = "test@example.com"
    token = generate_password_reset_token(email)
    send_reset_password_email(email, email, token)

    mock_send_email.assert_called_once()
    call_args = mock_send_email.call_args[1]

    assert call_args["email_to"] == email
    assert "Password recovery" in call_args["subject"]

    # Test that environment variables are passed correctly
    env = call_args["environment"]
    assert env["project_name"] == settings.PROJECT_NAME
    assert env["username"] == email
    assert env["valid_hours"] == settings.EMAIL_RESET_TOKEN_EXPIRE_HOURS
    assert env["link"] == f"{settings.SERVER_HOST}/reset-password?token={token}"

    # Create a JinjaTemplate and render it to verify template variables
    template = JinjaTemplate(call_args["html_content"])
    rendered = template.render(**env)

    assert "{{ project_name }}" not in rendered
    assert "{{ username }}" not in rendered
    assert "{{ link }}" not in rendered
    assert settings.PROJECT_NAME in rendered
    assert email in rendered
    assert token in rendered
