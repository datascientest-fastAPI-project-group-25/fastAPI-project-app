import logging
from datetime import datetime, timedelta
from typing import Any

import emails
from emails.template import JinjaTemplate
from fastapi import HTTPException, status
from jose import jwt
from pydantic.networks import EmailStr

from app.core.config import settings


def send_email(
    email_to: EmailStr,
    subject: str,
    html_content: str,
    environment: dict[str, Any] | None = None,
) -> None:
    """Send an email using the configured SMTP server or log it in development."""
    assert settings.EMAILS_FROM_EMAIL, "EMAILS_FROM_EMAIL must be set"

    # If SMTP is not configured, just log the email content
    if not settings.EMAILS_ENABLED:
        logging.info(f"Simulating email to {email_to}")
        logging.info(subject)
        logging.info(html_content)
        return

    message = emails.Message(
        subject=subject,
        html=JinjaTemplate(html_content),
        mail_from=(settings.EMAILS_FROM_NAME, settings.EMAILS_FROM_EMAIL),
    )
    smtp_options = {"host": settings.SMTP_HOST, "port": settings.SMTP_PORT}
    if settings.SMTP_TLS:
        smtp_options["tls"] = True
    if settings.SMTP_USER:
        smtp_options["user"] = settings.SMTP_USER
    if settings.SMTP_PASSWORD:
        smtp_options["password"] = settings.SMTP_PASSWORD

    response = message.send(to=email_to, render=environment, smtp=smtp_options)
    logging.info(f"send email result: {response}")


def generate_test_email() -> emails.Message:
    """Generate a test email with a template."""
    subject = "Test email"
    html_content = "<p>This is a test email. Congratulations, it worked!</p>"
    return emails.Message(subject=subject, html=JinjaTemplate(html_content))


def generate_new_account_email(email_to: EmailStr) -> None:
    """Send a welcome email to new users."""
    project_name = settings.PROJECT_NAME
    subject = f"Welcome to {project_name}"
    with open(settings.EMAIL_TEMPLATES_DIR / "new_account.html") as f:
        template_str = f.read()

    send_email(
        email_to=email_to,
        subject=subject,
        html_content=template_str,
        environment={
            "project_name": settings.PROJECT_NAME,
            "email": email_to,
        },
    )


def generate_password_reset_token(email: str, expires_delta: int = None) -> str:
    """Generate a password reset token for the given email."""
    if expires_delta is not None:
        delta = timedelta(hours=expires_delta)
    else:
        delta = timedelta(hours=settings.EMAIL_RESET_TOKEN_EXPIRE_HOURS)
    now = datetime.utcnow()
    expires = now + delta
    exp = expires.timestamp()
    encoded_jwt = jwt.encode(
        {"exp": exp, "nbf": now.timestamp(), "sub": email},
        settings.SECRET_KEY,
        algorithm="HS256",
    )
    return encoded_jwt


def verify_password_reset_token(token: str) -> str:
    """Verify a password reset token and return the email if valid."""
    try:
        decoded_token = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
        return decoded_token["sub"]
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid token",
        )


def send_reset_password_email(
    email_to: EmailStr,
    email: str,
    token: str,
) -> None:
    """Send a password reset email to the user."""
    project_name = settings.PROJECT_NAME
    subject = f"{project_name} - Password recovery for user {email}"
    with open(settings.EMAIL_TEMPLATES_DIR / "reset_password.html") as f:
        template_str = f.read()
    server_host = settings.SERVER_HOST
    link = f"{server_host}/reset-password?token={token}"
    send_email(
        email_to=email_to,
        subject=subject,
        html_content=template_str,
        environment={
            "project_name": settings.PROJECT_NAME,
            "username": email,
            "email": email_to,
            "valid_hours": settings.EMAIL_RESET_TOKEN_EXPIRE_HOURS,
            "link": link,
        },
    )
