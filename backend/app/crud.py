import uuid
from typing import Any

from sqlalchemy import func
from sqlmodel import Session, select

from app.core.security import get_password_hash, verify_password
from app.models import Item, ItemCreate, ItemUpdate, User, UserCreate, UserUpdate


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
        is_superuser=user_create.is_superuser,
        full_name=user_create.full_name,
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user


def update_user(
    session: Session,
    user_in: UserUpdate | dict[str, Any],
    db_user: User | None = None,
    user_id: uuid.UUID | None = None,
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

    if "password" in update_data and update_data["password"]:
        update_data["hashed_password"] = get_password_hash(update_data["password"])
        del update_data["password"]

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


def create_item(session: Session, item_create: ItemCreate, owner_id: int) -> Item:
    db_item = Item(
        title=item_create.title, description=item_create.description, owner_id=owner_id
    )
    session.add(db_item)
    session.commit()
    session.refresh(db_item)
    return db_item


def get_item(session: Session, item_id: int) -> Item | None:
    return session.get(Item, item_id)


def get_items(session: Session, skip: int = 0, limit: int = 100) -> list[Item]:
    return session.query(Item).offset(skip).limit(limit).all()


def update_item(session: Session, item: Item, item_update: ItemUpdate) -> Item:
    update_data = item_update.dict(exclude_unset=True)
    for field, value in update_data.items():
        setattr(item, field, value)
    session.commit()
    session.refresh(item)
    return item


def delete_item(session: Session, item: Item) -> None:
    session.delete(item)
    session.commit()
