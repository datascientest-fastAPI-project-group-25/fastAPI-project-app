import uuid

from fastapi import APIRouter, Body, Depends, HTTPException, status

from app import crud
from app.api.deps import (
    SessionDep,
    get_current_active_superuser,
    get_current_active_user,
)
from app.core.config import settings
from app.core.security import get_password_hash, verify_password
from app.models import (
    Item,
    ItemCreate,
    ItemUpdate,
    Message,
    Token,
    UpdatePassword,
    User,
    UserCreate,
    UserRegister,
    UsersPublic,
    UserUpdate,
)

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/", response_model=UsersPublic)
def get_users(
    *, db: SessionDep, skip: int = 0, limit: int = 100
) -> UsersPublic:
    """
    Get all users.
    """
    users = crud.get_users(db, skip=skip, limit=limit)
    count = crud.count_users(db)
    return UsersPublic(data=users, count=count)


@router.post("/", response_model=User)
def create_user(
    *, db: SessionDep, user_in: UserCreate, _current_user: User = Depends(get_current_active_superuser)
) -> User:
    """
    Create new user with the privileges of superuser.
    """
    user = crud.get_user_by_email(db, email=user_in.email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The user with this username already exists in the system.",
        )
    user = crud.create_user(db, user_create=user_in)
    return user


@router.post("/open", response_model=User)
def create_user_open(
    *, db: SessionDep, password: str = Body(...), email: str = Body(...), full_name: str = Body(None)
) -> User:
    """
    Create new user without the need to be logged in.
    """
    if not settings.USERS_OPEN_REGISTRATION:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Open user registration is forbidden on this server.",
        )
    user = crud.get_user_by_email(db, email=email)
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="The user with this username already exists in the system.",
        )
    user_in = UserCreate(password=password, email=email, full_name=full_name)
    user = crud.create_user(db, user_create=user_in)
    return user


@router.post("/signup", response_model=User)
def register_user(
    *, db: SessionDep, user_in: UserRegister
) -> User:
    """
    Register a new user.
    """
    if not settings.USERS_OPEN_REGISTRATION:
        raise HTTPException(
            status_code=403,
            detail="Open user registration is forbidden on this server.",
        )
    user = crud.get_user_by_email(db, email=user_in.email)
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
    user = crud.create_user(db, user_create=user_create)
    return user


@router.get("/me", response_model=User)
def read_user_me(_db: SessionDep, current_user: User = Depends(get_current_active_user)) -> User:
    """
    Get current user.
    """
    return current_user


@router.patch("/me", response_model=User)
def update_user_me(
    *,
    db: SessionDep,
    password: str = Body(None),
    full_name: str = Body(None),
    email: str = Body(None),
    current_user: User = Depends(get_current_active_user),
) -> User:
    """
    Update own user.
    """
    current_user_data = current_user.dict()
    user_in = UserUpdate(**current_user_data)
    if password is not None:
        user_in.password = password
    if full_name is not None:
        user_in.full_name = full_name
    if email is not None:
        # Check if email is being updated and if it already exists
        if email != current_user.email:
            existing_user = crud.get_user_by_email(db, email=email)
            if existing_user:
                raise HTTPException(
                    status_code=409,
                    detail="User with this email already exists",
                )
        user_in.email = email
    user = crud.update_user(db, db_user=current_user, user_in=user_in)
    return user


@router.get("/me/refresh-token", response_model=Token)
def refresh_token(current_user: User = Depends(get_current_active_user)) -> Token:
    """
    Get new tokens for user.
    """
    return crud.create_access_token(subject=current_user.id)


@router.patch("/me/password", response_model=Message)
def update_password_me(
    *,
    db: SessionDep,
    password_data: UpdatePassword,
    current_user: User = Depends(get_current_active_user),
) -> Message:
    """
    Update current user password.
    """
    if not verify_password(password_data.current_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect password",
        )

    if password_data.current_password == password_data.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="New password cannot be the same as the current password",
        )

    hashed_password = get_password_hash(password_data.new_password)
    current_user.hashed_password = hashed_password
    db.add(current_user)
    db.commit()
    db.refresh(current_user)

    return Message(message="Password updated successfully")


@router.delete("/me", response_model=Message)
def delete_user_me(
    *,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
) -> Message:
    """
    Delete current user.
    """
    if current_user.is_superuser:
        raise HTTPException(
            status_code=403,
            detail="Super users are not allowed to delete themselves",
        )
    crud.delete_user(db, user_id=current_user.id)
    return Message(message="User deleted successfully")


@router.get("/{user_id}", response_model=User)
def read_user_by_id(
    user_id: uuid.UUID,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
) -> User:
    """
    Get a specific user by id.
    """
    user = crud.get_user(db, user_id=user_id)
    if user == current_user:
        return user
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=403,
            detail="The user doesn't have enough privileges",
        )
    return user


@router.patch("/{user_id}", response_model=User)
def update_user(
    *,
    db: SessionDep,
    user_id: uuid.UUID,
    user_in: UserUpdate,
    _current_user: User = Depends(get_current_active_superuser),
) -> User:
    """
    Update a user.
    """
    user = crud.get_user(db, user_id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="The user with this id does not exist in the system",
        )

    # Check if email is being updated and if it already exists
    if user_in.email is not None and user_in.email != user.email:
        existing_user = crud.get_user_by_email(db, email=user_in.email)
        if existing_user:
            raise HTTPException(
                status_code=409,
                detail="User with this email already exists",
            )

    user = crud.update_user(db, db_user=user, user_in=user_in)
    return user


@router.delete("/{user_id}", response_model=Message)
def delete_user(
    *,
    db: SessionDep,
    user_id: uuid.UUID,
    current_user: User = Depends(get_current_active_superuser),
) -> Message:
    """
    Delete a user.
    """
    user = crud.get_user(db, user_id=user_id)
    if not user:
        raise HTTPException(
            status_code=404,
            detail="User not found",
        )
    if user == current_user:
        raise HTTPException(
            status_code=403,
            detail="Super users are not allowed to delete themselves",
        )
    crud.delete_user(db, user_id=user.id)
    return Message(message="User deleted successfully")


@router.get("/me/items/")
def read_user_items(
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
) -> list[Item]:
    """
    Get all items for the current user.
    """
    return crud.get_user_items(db, user_id=current_user.id)


@router.get("/me/items/{item_id}")
def read_user_item(
    item_id: int,
    db: SessionDep,
    current_user: User = Depends(get_current_active_user),
) -> Item:
    """
    Get a specific item for the current user.
    """
    item = crud.get_item(db, item_id=item_id)
    if not item:
        raise HTTPException(
            status_code=404,
            detail="The item with this id does not exist in the system",
        )
    if item.owner_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="The user doesn't have enough privileges",
        )
    return item


@router.post("/me/items/")
def create_user_item(
    *,
    db: SessionDep,
    item_in: ItemCreate,
    current_user: User = Depends(get_current_active_user),
) -> Item:
    """
    Create a new item for the current user.
    """
    return crud.create_user_item(db, item_in=item_in, user_id=current_user.id)


@router.put("/me/items/{item_id}")
def update_user_item(
    *,
    db: SessionDep,
    item_id: int,
    item_in: ItemUpdate,
    current_user: User = Depends(get_current_active_user),
) -> Item:
    """
    Update a specific item for the current user.
    """
    item = crud.get_item(db, item_id=item_id)
    if not item:
        raise HTTPException(
            status_code=404,
            detail="The item with this id does not exist in the system",
        )
    if item.owner_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="The user doesn't have enough privileges",
        )
    return crud.update_item(db, db_obj=item, obj_in=item_in)


@router.delete("/me/items/{item_id}")
def delete_user_item(
    *,
    db: SessionDep,
    item_id: int,
    current_user: User = Depends(get_current_active_user),
) -> Message:
    """
    Delete a specific item for the current user.
    """
    item = crud.get_item(db, item_id=item_id)
    if not item:
        raise HTTPException(
            status_code=404,
            detail="The item with this id does not exist in the system",
        )
    if item.owner_id != current_user.id:
        raise HTTPException(
            status_code=403,
            detail="The user doesn't have enough privileges",
        )
    crud.delete_item(db, item=item)
    return Message(message="The item has been successfully deleted")
