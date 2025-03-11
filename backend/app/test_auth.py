"""
Test script to verify authentication functionality directly.
"""
import logging
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import get_password_hash, verify_password
from app.models import User
from app.crud import get_user_by_email, authenticate

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Test credentials from memory
TEST_EMAIL = "admin@example.com"
TEST_PASSWORD = "FastAPI_Secure_2025!"

def test_password_hashing():
    """Test that password hashing and verification works correctly."""
    logger.info("Testing password hashing and verification...")
    
    # Hash a test password
    hashed_password = get_password_hash(TEST_PASSWORD)
    logger.info(f"Hashed password: {hashed_password}")
    
    # Verify the test password against the hash
    is_valid = verify_password(TEST_PASSWORD, hashed_password)
    logger.info(f"Password verification result: {is_valid}")
    
    return is_valid

def test_authentication(session: Session):
    """Test authentication with the database."""
    logger.info(f"Testing authentication for user: {TEST_EMAIL}")
    
    # Get the user from the database
    user = get_user_by_email(session=session, email=TEST_EMAIL)
    if not user:
        logger.error(f"User not found: {TEST_EMAIL}")
        return False
    
    logger.info(f"Found user: {user.email}, Active: {user.is_active}, Superuser: {user.is_superuser}")
    logger.info(f"Hashed password in DB: {user.hashed_password}")
    
    # Test direct password verification
    direct_verify = verify_password(TEST_PASSWORD, user.hashed_password)
    logger.info(f"Direct password verification: {direct_verify}")
    
    # Test authentication through the authenticate function
    authenticated_user = authenticate(session=session, email=TEST_EMAIL, password=TEST_PASSWORD)
    auth_result = authenticated_user is not None
    logger.info(f"Authentication result: {auth_result}")
    
    if not auth_result:
        logger.error("Authentication failed")
    else:
        logger.info("Authentication successful")
    
    return auth_result

if __name__ == "__main__":
    # Import here to avoid circular imports
    from app.api.deps import get_db
    
    logger.info("Starting authentication test...")
    
    # Test password hashing
    hash_test_result = test_password_hashing()
    logger.info(f"Password hashing test result: {hash_test_result}")
    
    # Get a database session
    db = next(get_db())
    
    # Test authentication
    auth_test_result = test_authentication(db)
    logger.info(f"Authentication test result: {auth_test_result}")
