"""
Test script to verify authentication functionality directly.
"""

import logging

from app.core.security import get_password_hash, verify_password

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Test credentials from memory
TEST_EMAIL = "admin@example.com"
# Using an environment variable would be better in production code
# This is intentionally hardcoded for testing purposes only
TEST_PASSWORD = "test_password_for_ci"  # nosec


def test_password_hashing():
    """Test that password hashing and verification works correctly."""
    logger.info("Testing password hashing and verification...")
    # Hash a test password
    hashed_password = get_password_hash(TEST_PASSWORD)
    logger.info(f"Hashed password: {hashed_password}")
    # Verify the test password against the hash
    is_valid = verify_password(TEST_PASSWORD, hashed_password)
    logger.info(f"Password verification result: {is_valid}")
    if not is_valid:
        logger.error("Password verification failed")
        return False
    return True


def test_authentication():
    """Test authentication without database connection.

    This is a simplified test that only tests password hashing and
    verification,
    without requiring a database session. For full authentication testing,
    use the tests in the app/tests directory.
    """
    logger.info(f"Testing simplified authentication for user: {TEST_EMAIL}")
    # Create a mock hashed password
    hashed_password = get_password_hash(TEST_PASSWORD)
    logger.info(f"Created mock hashed password: {hashed_password}")
    # Test direct password verification
    direct_verify = verify_password(TEST_PASSWORD, hashed_password)
    logger.info(f"Direct password verification: {direct_verify}")
    if not direct_verify:
        logger.error("Direct password verification failed")
        return False
    return True


if __name__ == "__main__":
    logger.info("Starting authentication test...")

    # Test password hashing
    hash_test_result = test_password_hashing()
    logger.info(f"Password hashing test result: {hash_test_result}")

    # Test authentication
    auth_test_result = test_authentication()
    logger.info(f"Authentication test result: {auth_test_result}")
