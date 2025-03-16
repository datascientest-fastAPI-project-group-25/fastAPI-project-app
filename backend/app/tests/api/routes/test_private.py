from fastapi.testclient import TestClient
from sqlmodel import Session, select

from app.core.config import settings
from app.models import User


def test_create_user(client: TestClient, db: Session) -> None:
    r = client.post(
        f"{settings.API_V1_STR}/private/users/",
        json={
            "email": "pollo@listo.com",
            "password": "password123",
            "full_name": "Pollo Listo",
        },
    )

    if r.status_code != 200:
        raise ValueError(f"Expected status code 200, got {r.status_code}")

    data = r.json()

    user = db.exec(select(User).where(User.id == data["id"])).first()

    if not user:
        raise ValueError("User not found in database after creation")
    if user.email != "pollo@listo.com":
        raise ValueError(f"Expected email 'pollo@listo.com', got '{user.email}'")
    if user.full_name != "Pollo Listo":
        raise ValueError(f"Expected full name 'Pollo Listo', got '{user.full_name}'")
