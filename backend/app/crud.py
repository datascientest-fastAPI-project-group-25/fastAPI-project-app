import uuid
from typing import List
from sqlmodel import Session, func, select

from app.models import User, Item
from app.schemas import UserCreate, UserUpdate, ItemCreate, ItemUpdate
from app.core.security import get_password_hash, verify_password

# User CRUD operations

def count_users(session: Session) -> int:
    """Count all users in the database."""
    statement = select(func.count()).select_from(User)
    return session.exec(statement).one()

def create_user(session: Session, user_create: UserCreate) -> User:
    """Create a new user."""
    hashed_password = get_password_hash(user_create.password)
    db_user = User(
        email=user_create.email,
        hashed_password=hashed_password,
        is_active=user_create.is_active,
        is_superuser=user_create.is_superuser,
        full_name=user_create.full_name
    )
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

def get_user_by_email(session: Session, email: str) -> User | None:
    """Get a user by email."""
    statement = select(User).where(User.email == email)
    return session.exec(statement).first()

def authenticate(session: Session, email: str, password: str) -> User | None:
    """Authenticate a user."""
    user = get_user_by_email(session=session, email=email)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user

def get_user(session: Session, user_id: uuid.UUID) -> User | None:
    """Get a user by ID."""
    return session.get(User, user_id)

def get_users(session: Session, skip: int = 0, limit: int = 100) -> List[User]:
    """Get a list of users."""
    statement = select(User).offset(skip).limit(limit)
    return session.exec(statement).all()

def update_user(session: Session, db_user: User, user_in: UserUpdate) -> User:
    """Update a user."""
    user_data = user_in.model_dump(exclude_unset=True)
    if "password" in user_data:
        hashed_password = get_password_hash(user_data["password"])
        del user_data["password"]
        user_data["hashed_password"] = hashed_password
    for key, value in user_data.items():
        setattr(db_user, key, value)
    session.add(db_user)
    session.commit()
    session.refresh(db_user)
    return db_user

# Item CRUD operations

def create_item(session: Session, item_in: ItemCreate, owner_id: uuid.UUID) -> Item:
    """Create a new item."""
    db_item = Item(
        title=item_in.title,
        description=item_in.description,
        owner_id=owner_id
    )
    session.add(db_item)
    session.commit()
    session.refresh(db_item)
    return db_item

def get_item(session: Session, item_id: uuid.UUID) -> Item | None:
    """Get an item by ID."""
    return session.get(Item, item_id)

def get_items(session: Session, skip: int = 0, limit: int = 100) -> List[Item]:
    """Get a list of items."""
    statement = select(Item).offset(skip).limit(limit)
    return session.exec(statement).all()

def get_items_by_owner(
    session: Session, owner_id: uuid.UUID, skip: int = 0, limit: int = 100
) -> List[Item]:
    """Get items by owner ID."""
    statement = select(Item).where(Item.owner_id == owner_id).offset(skip).limit(limit)
    return session.exec(statement).all()

def update_item(session: Session, db_item: Item, item_in: ItemUpdate) -> Item:
    """Update an item."""
    item_data = item_in.model_dump(exclude_unset=True)
    for key, value in item_data.items():
        setattr(db_item, key, value)
    session.add(db_item)
    session.commit()
    session.refresh(db_item)
    return db_item

def delete_item(session: Session, db_item: Item) -> None:
    """Delete an item."""
    session.delete(db_item)
    session.commit()
