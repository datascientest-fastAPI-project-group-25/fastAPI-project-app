import logging
from typing import Any

import emails
from emails.template import JinjaTemplate
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
    return emails.Message(
        subject=subject,
        html=JinjaTemplate(html_content),
        mail_from=(settings.EMAILS_FROM_NAME, settings.EMAILS_FROM_EMAIL),
    )
