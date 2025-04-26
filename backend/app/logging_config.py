import logging
import os
import sys
from typing import Optional

from app.core.config import settings

def setup_logging(log_level: Optional[str] = None) -> None:
    """
    Configure logging for the application.

    Args:
        log_level: Optional log level to override the default from settings
    """
    # Get log level from settings or override
    level = log_level or os.environ.get("LOG_LEVEL", "INFO").upper()

    # Configure root logger
    logging.basicConfig(
        level=level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        stream=sys.stdout,  # Log to stdout for container compatibility
        datefmt='%Y-%m-%d %H:%M:%S'
    )

    # Configure uvicorn access logger
    access_logger = logging.getLogger("uvicorn.access")
    access_logger.handlers = []  # Remove default handlers

    # Configure uvicorn error logger
    error_logger = logging.getLogger("uvicorn.error")
    error_logger.handlers = []  # Remove default handlers

    # Set up structured logging for application
    app_logger = logging.getLogger("app")
    app_logger.setLevel(level)

    # Add structured logging formatter if needed
    structured_logging = os.environ.get("STRUCTURED_LOGGING", "false").lower() == "true"
    if structured_logging:
        formatter = logging.Formatter(
            '{"timestamp": "%(asctime)s", "level": "%(levelname)s", '
            '"name": "%(name)s", "message": "%(message)s"}',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        handler = logging.StreamHandler(sys.stdout)
        handler.setFormatter(formatter)
        app_logger.handlers = [handler]
