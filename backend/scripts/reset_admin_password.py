#!/usr/bin/env python3
"""
Reset the admin password to a known value.
"""

import logging
import os
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger("password_reset")

# Add the parent directory to the Python path to make 'app' importable
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    logger.info("Importing required modules...")
    from sqlmodel import Session, select

    from app.core.db import engine
    from app.core.security import get_password_hash
    from app.models import User

    logger.info("Successfully imported all required modules")
except ImportError as e:
    logger.error(f"Error importing required modules: {e}")
    sys.exit(1)


def reset_admin_password():
    """Reset the admin user password to 'adminadmin123'."""
    try:
        logger.info("Starting admin password reset process...")
        # Create a new session
        with Session(engine) as session:
            # Find the admin user
            admin_email = "admin@example.com"
            user = session.exec(select(User).where(User.email == admin_email)).first()

            if not user:
                logger.error(f"Admin user with email {admin_email} not found!")
                sys.exit(1)

            # Set the new password
            new_password = "adminadmin123"
            user.hashed_password = get_password_hash(new_password)

            # Commit the changes
            session.add(user)
            session.commit()

            logger.info(f"Successfully reset password for {admin_email}")
            logger.info(
                f"New login credentials: Email: {admin_email}, Password: {new_password}"
            )

    except Exception as e:
        logger.error(f"Failed to reset admin password: {e}")
        sys.exit(1)


if __name__ == "__main__":
    reset_admin_password()
