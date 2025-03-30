import uuid
from typing import Any, Dict, List, Optional, Union

from sqlmodel import Session, select, func

from app.core.security import get_password_hash
from app.models import User, UserCreate, UserUpdate


def get_user(session: Session, user_id: uuid.UUID) -> Optional[User]:
    return session.get(User, user_id)


def get_user_by_email(session: Session, email: str) -> Optional[User]:
    return session.exec(select(User).where(User.email == email)).first()


def get_users(session: Session, skip: int = 0, limit: int = 100) -> List[User]:
    return session.exec(select(User).offset(skip).limit(limit)).all()


def create_user(session: Session, user: UserCreate) -> User:
    db_user = User(
        email=user.email,
        hashed_password=get_password_hash(user.password),
        is_active=True,
        is_superuser=False,
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def update_user(
    session: Session, user_id: uuid.UUID, user_in: Union[UserUpdate, Dict[str, Any]]
) -> Optional[User]:
    db_user = get_user(session, user_id)
    if db_user is None:
        return None

    if isinstance(user_in, dict):
        update_data = user_in
    else:
        update_data = user_in.dict(exclude_unset=True)

    for field, value in update_data.items():
        setattr(db_user, field, value)

    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def delete_user(session: Session, user_id: uuid.UUID) -> Optional[User]:
    db_user = get_user(session, user_id)
    if db_user is None:
        return None
    session.delete(db_user)
    session.commit()
    return db_user


def authenticate_user(session: Session, email: str, password: str) -> Optional[User]:
    user = get_user_by_email(session, email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


def get_active_users(session: Session) -> List[User]:
    return session.exec(select(User).where(User.is_active == True)).all()


def get_superusers(session: Session) -> List[User]:
    return session.exec(select(User).where(User.is_superuser == True)).all()
