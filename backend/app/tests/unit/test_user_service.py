from unittest.mock import MagicMock, patch

from sqlalchemy.orm import Session

from app.crud import create_user
from app.models.user import User
from app.schemas.user import UserCreate


def test_create_user():
    """Test user creation function with mocked session."""
    # Setup
    mock_session = MagicMock(spec=Session)
    user_data = UserCreate(email="test@example.com", password="testpassword")

    # Execute
    with patch("app.crud.get_password_hash", return_value="hashed_password"):
        result = create_user(session=mock_session, user_create=user_data)

    # Assert
    mock_session.add.assert_called_once()
    mock_session.commit.assert_called_once()
    mock_session.refresh.assert_called_once()
    assert result.email == user_data.email
    assert result.hashed_password == "hashed_password"


def test_user_model_validation():
    """Test User model validation with direct instantiation."""
    # Setup
    user_data = {
        "email": "test@example.com",
        "hashed_password": "hashed_password",
        "is_active": True,
        "is_superuser": False,
    }

    # Execute
    user = User(**user_data)

    # Assert
    assert user.email == user_data["email"]
    assert user.hashed_password == user_data["hashed_password"]
    assert user.is_active == user_data["is_active"]
    assert user.is_superuser == user_data["is_superuser"]
