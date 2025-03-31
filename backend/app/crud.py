import uuid
from typing import Any

from sqlalchemy import func
from sqlmodel import Session, select

from app.core.security import get_password_hash, verify_password
from app.models import User, UserCreate, UserUpdate


def get_user(session: Session, user_id: uuid.UUID) -> User | None:
    return session.get(User, user_id)


def get_user_by_email(session: Session, email: str) -> User | None:
    return session.exec(select(User).where(User.email == email)).first()


def get_users(session: Session, skip: int = 0, limit: int = 100) -> list[User]:
    statement = select(User).offset(skip).limit(limit)
    return session.exec(statement).all()


def create_user(session: Session, user_create: UserCreate) -> User:
    db_user = User(
        email=user_create.email,
        hashed_password=get_password_hash(user_create.password),
        is_active=True,
        is_superuser=False,
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def update_user(
    session: Session, user_in: UserUpdate | dict[str, Any], db_user: User | None = None, user_id: uuid.UUID | None = None
) -> User | None:
    if db_user is None and user_id is not None:
        db_user = get_user(session, user_id)
    if db_user is None:
        return None

    if isinstance(user_in, dict):
        update_data = user_in
    else:
        # Handle both Pydantic v1 and v2
        if hasattr(user_in, "model_dump"):
            update_data = user_in.model_dump(exclude_unset=True)
        else:
            update_data = user_in.dict(exclude_unset=True)

    for field, value in update_data.items():
        setattr(db_user, field, value)

    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def delete_user(session: Session, user_id: uuid.UUID) -> User | None:
    db_user = get_user(session, user_id)
    if db_user is None:
        return None
    session.delete(db_user)
    session.commit()
    return db_user


def authenticate_user(session: Session, email: str, password: str) -> User | None:
    user = get_user_by_email(session, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def get_active_users(session: Session) -> list[User]:
    return session.exec(select(User).where(User.is_active.is_(True))).all()


def get_superusers(session: Session) -> list[User]:
    return session.exec(select(User).where(User.is_superuser.is_(True))).all()

def count_users(session: Session) -> int:
    statement = select(func.count()).select_from(User)
    result = session.exec(statement).one()
    return result
