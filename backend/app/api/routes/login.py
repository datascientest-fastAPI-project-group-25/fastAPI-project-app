from datetime import timedelta
from pathlib import Path
from typing import Any

from fastapi import APIRouter, Body, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlmodel import select

from app.api.deps import SessionDep
from app.core.config import settings
from app.core.security import create_access_token, get_password_hash, verify_password
from app.models import Message, Token, User
from app.utils import (
    generate_password_reset_token,
    send_email,
    verify_password_reset_token,
)

router = APIRouter(prefix="/login", tags=["login"])


def send_recovery_email(email_to: str, username: str, token: str) -> None:
    """Send recovery email to user."""
    project_name = settings.PROJECT_NAME
    subject = f"{project_name} - Password Recovery"
    with open(Path(settings.EMAIL_TEMPLATES_DIR) / "recovery.html") as f:
        template_str = f.read()
    send_email(
        email_to=email_to,
        subject_template=subject,
        html_template=template_str,
        environment={
            "project_name": settings.PROJECT_NAME,
            "username": username,
            "email": email_to,
            "valid_hours": settings.EMAIL_RESET_TOKEN_EXPIRE_HOURS,
            "link": f"{settings.SERVER_HOST}/reset-password?token={token}",
        },
    )


def send_reset_password_email(email_to: str, token: str) -> None:
    """Send password reset email to user."""
    project_name = settings.PROJECT_NAME
    subject = f"{project_name} - Password reset"
    with open(Path(settings.EMAIL_TEMPLATES_DIR) / "reset_password.html") as f:
        template_str = f.read()
    send_email(
        email_to=email_to,
        subject_template=subject,
        html_template=template_str,
        environment={
            "project_name": settings.PROJECT_NAME,
            "email": email_to,
            "valid_hours": settings.EMAIL_RESET_TOKEN_EXPIRE_HOURS,
            "link": f"{settings.SERVER_HOST}/new-password?token={token}",
        },
    )


def send_new_account_email(email_to: str, username: str, password: str) -> None:
    """Send new account email to user."""
    project_name = settings.PROJECT_NAME
    subject = f"{project_name} - New account for user {username}"
    with open(Path(settings.EMAIL_TEMPLATES_DIR) / "new_account.html") as f:
        template_str = f.read()
    send_email(
        email_to=email_to,
        subject_template=subject,
        html_template=template_str,
        environment={
            "project_name": settings.PROJECT_NAME,
            "username": username,
            "password": password,
            "email": email_to,
        },
    )


@router.post("/access-token", response_model=Token)
def login_access_token(
    db: SessionDep, form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    user = db.exec(select(User).where(User.email == form_data.username)).first()
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password",
        )
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        subject=user.email, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/password-recovery/{email}", response_model=Message)
def recover_password(email: str, db: SessionDep) -> Any:
    """
    Password Recovery
    """
    user = db.exec(select(User).where(User.email == email)).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="The user with this username does not exist in the system.",
        )
    password_reset_token = generate_password_reset_token(email=email)
    send_reset_password_email(
        email_to=user.email,
        token=password_reset_token,
    )
    return {"msg": "Password recovery email sent"}


@router.post("/reset-password/", response_model=Message)
def reset_password(
    db: SessionDep,
    token: str = Body(...),
    new_password: str = Body(...),
) -> Any:
    """
    Reset password
    """
    email = verify_password_reset_token(token)
    if not email:
        raise HTTPException(status_code=400, detail="Invalid token")
    user = db.exec(select(User).where(User.email == email)).first()
    if not user:
        raise HTTPException(
            status_code=404,
            detail="The user with this username does not exist in the system",
        )
    hashed_password = get_password_hash(new_password)
    user.hashed_password = hashed_password
    db.add(user)
    db.commit()
    return {"msg": "Password updated successfully"}
