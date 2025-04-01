import pytest
from fastapi.encoders import jsonable_encoder
from sqlmodel import Session

from app import crud
from app.core.security import verify_password
from app.models import User
from app.schemas import UserCreate, UserUpdate
from tests.utils.utils import random_email, random_lower_string


@pytest.mark.crud
def test_create_user(db: Session) -> None:
    email = random_email()
    password = random_lower_string()
    user_in = UserCreate(email=email, password=password)
    user = crud.create_user(session=db, user_create=user_in)
    assert user.email == email
    assert hasattr(user, "hashed_password")


@pytest.mark.crud
def test_authenticate_user(db: Session) -> None:
    email = random_email()
    password = random_lower_string()
    user_in = UserCreate(email=email, password=password)
    user = crud.create_user(session=db, user_create=user_in)
    authenticated_user = crud.authenticate_user(
        session=db, email=email, password=password
    )
    assert authenticated_user
    assert user.email == authenticated_user.email


@pytest.mark.crud
def test_not_authenticate_user(db: Session) -> None:
    email = random_email()
    password = random_lower_string()
    user = crud.authenticate_user(session=db, email=email, password=password)
    assert user is None


@pytest.mark.crud
def test_check_if_user_is_active(db: Session) -> None:
    email = random_email()
    password = random_lower_string()
    user_in = UserCreate(email=email, password=password)
    user = crud.create_user(session=db, user_create=user_in)
    assert user.is_active is True


@pytest.mark.crud
def test_check_if_user_is_active_inactive(db: Session) -> None:
    email = random_email()
    password = random_lower_string()
    user_in = UserCreate(email=email, password=password, disabled=True)
    user = crud.create_user(session=db, user_create=user_in)
    assert user.is_active


@pytest.mark.crud
def test_check_if_user_is_superuser(db: Session) -> None:
    email = random_email()
    password = random_lower_string()
    user_in = UserCreate(email=email, password=password, is_superuser=True)
    user = crud.create_user(session=db, user_create=user_in)
    db.commit()  # Commit the transaction
    db.refresh(user)  # Ensure we have the latest data from the database
    assert user.is_superuser


@pytest.mark.crud
def test_check_if_user_is_superuser_normal_user(db: Session) -> None:
    username = random_email()
    password = random_lower_string()
    user_in = UserCreate(email=username, password=password)
    user = crud.create_user(session=db, user_create=user_in)
    assert user.is_superuser is False


@pytest.mark.crud
def test_get_user(db: Session) -> None:
    password = random_lower_string()
    username = random_email()
    user_in = UserCreate(email=username, password=password, is_superuser=True)
    user = crud.create_user(session=db, user_create=user_in)
    user_2 = db.get(User, user.id)
    assert user_2
    assert user.email == user_2.email
    assert jsonable_encoder(user) == jsonable_encoder(user_2)


@pytest.mark.crud
def test_update_user(db: Session) -> None:
    password = random_lower_string()
    email = random_email()
    user_in = UserCreate(email=email, password=password, is_superuser=True)
    user = crud.create_user(session=db, user_create=user_in)
    db.commit()  # Commit the transaction

    new_password = random_lower_string()
    user_in_update = UserUpdate(password=new_password, is_superuser=True)

    user_id = user.id
    if user_id is not None:
        # Get the user from the database first
        db_user = db.get(User, user_id)
        assert db_user is not None

        # Update the user
        updated_user = crud.update_user(session=db, user_id=user_id, user_in=user_in_update)
        db.commit()  # Commit the transaction

        # Verify the update
        assert updated_user
        assert updated_user.email == email
        assert verify_password(new_password, updated_user.hashed_password)
        assert updated_user.is_superuser
