from datetime import datetime, timedelta, timezone
from typing import Any
import logging

import jwt
from passlib.context import CryptContext

from app.core.config import settings

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Try to create a CryptContext with bcrypt, but fall back to a simpler scheme if there's an issue
try:
    pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
    # Test that it works
    test_hash = pwd_context.hash("test")
    logger.info("Successfully initialized bcrypt password hashing")
except Exception as e:
    logger.warning(f"Error initializing bcrypt: {e}. Falling back to sha256_crypt")
    # Fall back to sha256_crypt which has fewer dependencies
    pwd_context = CryptContext(schemes=["sha256_crypt"], deprecated="auto")


ALGORITHM = "HS256"


def create_access_token(subject: str | Any, expires_delta: timedelta) -> str:
    expire = datetime.now(timezone.utc) + expires_delta
    to_encode = {"exp": expire, "sub": str(subject)}
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt


def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)
