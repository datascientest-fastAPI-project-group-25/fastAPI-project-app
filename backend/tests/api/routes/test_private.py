import uuid

from fastapi.testclient import TestClient
from sqlmodel import Session, select

from app.core.config import settings
from app.models import User


def test_create_user(client: TestClient, db: Session) -> None:
    # Test data
    test_email = "pollo@listo.com"
    test_password = "password123"
    test_full_name = "Pollo Listo"

    # Send request to create user
    r = client.post(
        f"{settings.API_V1_STR}/private/users/",
        json={
            "email": test_email,
            "password": test_password,
            "full_name": test_full_name,
        },
    )

    # Verify response status code
    if r.status_code != 200:
        raise ValueError(
            f"Expected status code 200, got {r.status_code}. Response: {r.text}"
        )

    # Parse response data
    data = r.json()
    if "id" not in data:
        raise ValueError(f"Expected 'id' in response data, got: {data}")

    # Verify user was created in database
    user_id = uuid.UUID(data["id"])
    user = db.exec(select(User).where(User.id == user_id)).first()
    if not user:
        raise ValueError(f"User with id {user_id} not found in database after creation")

    # Verify user data
    if user.email != test_email:
        raise ValueError(f"Expected email '{test_email}', got '{user.email}'")
    if user.full_name != test_full_name:
        raise ValueError(
            f"Expected full name '{test_full_name}', got '{user.full_name}'"
        )

    # Verify password is not stored in plaintext
    if user.hashed_password == test_password:
        raise ValueError("Password is stored in plaintext, which is a security risk")
