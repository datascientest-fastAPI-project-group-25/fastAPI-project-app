import uuid
from typing import Any

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import col, delete

from app import crud
from app.api.deps import (
    CurrentUser,
    SessionDep,
    get_current_active_superuser,
)
from app.core.config import settings
from app.core.security import get_password_hash, verify_password
from app.models import (
    Item,
    Message,
    UpdatePassword,
    User,
    UserCreate,
    UserPublic,
    UserRegister,
    UsersPublic,
    UserUpdate,
    UserUpdateMe,
)
from app.utils import generate_new_account_email, send_email

router = APIRouter(prefix="/users", tags=["users"])


@router.get(
    "/",
    dependencies=[Depends(get_current_active_superuser)],
    response_model=UsersPublic,
)
def read_users(session: SessionDep, skip: int = 0, limit: int = 100) -> Any:
    """
    Retrieve users.
    """
    count = crud.count_users(session)
    users = crud.get_users(session, skip=skip, limit=limit)
    return UsersPublic(data=users, count=count)


@router.post("/", response_model=UserPublic)
def create_user(  # type: ignore[unused-argument] # noqa: ARG001 - current_user required by FastAPI for auth
    *,
    session: SessionDep,
    user_in: UserCreate,
    current_user: User = Depends(get_current_active_superuser),  # noqa: ARG001 - Used by dependency for auth
) -> Any:
    """
    Create new user.

    Args:
        session: Database session
        user_in: User creation data
        current_user: Admin user performing the creation (required for authorization)
    """
    user = crud.get_user_by_email(session=session, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this username already exists in the system.",
        )
    user = crud.create_user(session=session, user_create=user_in)
    # Explicitly use current_user for logging
    admin_email: str = current_user.email
    new_user_email: str = user.email
    print(f"User {new_user_email} created by admin {admin_email}")
    return user


@router.get("/me", response_model=UserPublic)
def read_user_me(current_user: CurrentUser) -> Any:
    """
    Get current user.
    """
    return current_user


@router.patch("/me", response_model=UserPublic)  # Changed method from PUT to PATCH
def update_user_me(
    *,
    session: SessionDep,
    user_in: UserUpdateMe,
    current_user: CurrentUser,
) -> Any:
    """
    Update own user.
    """
    if user_in.email is not None and user_in.email != current_user.email:
        if crud.get_user_by_email(session=session, email=user_in.email):
            raise HTTPException(
                status_code=409,
                detail="User with this email already exists",  # Corrected message
            )

    user_data = user_in.model_dump(exclude_unset=True)
    updated_user = crud.update_user(
        session=session, db_user=current_user, user_in=UserUpdate(**user_data)
    )
    return updated_user


@router.patch(
    "/me/password", response_model=Message
)  # Changed method from PUT to PATCH
def update_password_me(
    *,
    session: SessionDep,
    update_password: UpdatePassword,
    current_user: CurrentUser,
) -> Any:
    """
    Update own password.
    """
    if not verify_password(
        update_password.current_password, current_user.hashed_password
    ):
        raise HTTPException(status_code=400, detail="Incorrect password")

    if update_password.current_password == update_password.new_password:
        raise HTTPException(
            status_code=400,
            detail="New password cannot be the same as the current password",
        )

    hashed_password = get_password_hash(update_password.new_password)
    current_user.hashed_password = hashed_password
    session.add(current_user)
    session.commit()
    return Message(message="Password updated successfully")


@router.post("/signup", response_model=UserPublic)
def register_user(
    *,
    session: SessionDep,
    user_in: UserRegister,
) -> Any:
    """
    Register new user.
    """
    if not settings.USERS_OPEN_REGISTRATION:
        raise HTTPException(
            status_code=403,
            detail="Open user registration is forbidden on this server",
        )
    user = crud.get_user_by_email(session=session, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=400,
            detail="The user with this email already exists in the system",
        )
    user_create = UserCreate(
        email=user_in.email,
        password=user_in.password,
        full_name=user_in.full_name,
    )
    user = crud.create_user(session=session, user_create=user_create)

    if settings.emails_enabled and user_in.email:  # Corrected attribute access
        send_email(
            email_to=user_in.email,
            subject=f"{settings.PROJECT_NAME} - New account",
            html_content=generate_new_account_email(
                username=user_in.email, password=user_in.password
            ),
        )
    return user


@router.get("/{user_id}", response_model=UserPublic)
def read_user_by_id(
    user_id: uuid.UUID,
    current_user: CurrentUser,
    session: SessionDep,
) -> Any:
    """
    Get a specific user by id.
    """
    # Check permissions first
    if user_id != current_user.id and not current_user.is_superuser:
        raise HTTPException(
            status_code=403, detail="The user doesn't have enough privileges"
        )

    user = crud.get_user(session=session, user_id=user_id)
    if not user:
        raise HTTPException(
            status_code=404, detail="User not found"
        )  # Correct message if not found after permission check

    return user


@router.patch("/{user_id}", response_model=UserPublic)
def update_user(  # type: ignore[unused-argument] # noqa: ARG001 - current_user required by FastAPI for auth
    *,
    session: SessionDep,
    user_id: uuid.UUID,
    user_in: UserUpdate,
    current_user: User = Depends(get_current_active_superuser),  # noqa: ARG001 - Used by dependency for auth
) -> Any:
    """
    Update a user.

    Args:
        session: Database session
        user_id: ID of the user to update
        user_in: User update data
        current_user: Admin user performing the update (required for authorization)
    """
    user = crud.get_user(session=session, user_id=user_id)
    if not user:
        raise HTTPException(
            status_code=404,
            detail="The user with this id does not exist in the system",
        )
    if user_in.email is not None and user_in.email != user.email:
        existing_user = crud.get_user_by_email(session=session, email=user_in.email)
        if (
            existing_user and existing_user.id != user_id
        ):  # Check if the email belongs to another user
            raise HTTPException(
                status_code=409,
                detail="User with this email already exists",  # Corrected message
            )
    # Explicitly use current_user for logging
    admin_email: str = current_user.email
    updated_user_email: str = user.email
    print(f"User {updated_user_email} updated by admin {admin_email}")
    user = crud.update_user(session=session, db_user=user, user_in=user_in)
    return user


@router.delete("/me", response_model=Message)
def delete_user_me(
    *,
    session: SessionDep,
    current_user: CurrentUser,
) -> Any:
    """
    Delete own user.
    """
    if current_user.is_superuser:
        raise HTTPException(
            status_code=403,
            detail="Super users are not allowed to delete themselves",
        )
    statement = delete(Item).where(col(Item.owner_id) == current_user.id)
    session.exec(statement)
    session.delete(current_user)
    session.commit()
    return Message(message="User deleted successfully")


@router.delete("/{user_id}", response_model=Message)
def delete_user(
    *,
    session: SessionDep,
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_active_superuser),
) -> Any:
    """
    Delete a user.
    """
    user = crud.get_user(session=session, user_id=user_id)
    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )
    if user.id == current_user.id:
        raise HTTPException(
            status_code=403,
            detail="Super users are not allowed to delete themselves",
        )
    statement = delete(Item).where(col(Item.owner_id) == user.id)
    session.exec(statement)
    session.delete(user)
    session.commit()
    return Message(message="User deleted successfully")
