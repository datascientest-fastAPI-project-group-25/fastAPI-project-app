import logging
import os

from sqlmodel import Session, select
from tenacity import after_log, before_log, retry, stop_after_attempt, wait_fixed

from app.core.db import engine, engine_connect, init_db

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Print environment variables for debugging
logger.info("Environment variables:")
logger.info(f"PYTHONPATH: {os.environ.get('PYTHONPATH')}")
logger.info(f"DATABASE_URL: {os.environ.get('DATABASE_URL')}")
logger.info(f"POSTGRES_SERVER: {os.environ.get('POSTGRES_SERVER')}")
logger.info(f"POSTGRES_USER: {os.environ.get('POSTGRES_USER')}")
logger.info(f"POSTGRES_DB: {os.environ.get('POSTGRES_DB')}")

# Allow more time for database to be ready in containerized environments
max_tries = 60 * 10  # 10 minutes
wait_seconds = 1


@retry(
    stop=stop_after_attempt(max_tries),
    wait=wait_fixed(wait_seconds),
    before=before_log(logger, logging.INFO),
    after=after_log(logger, logging.WARN),
)
def init() -> None:
    try:
        logger.info("Attempting to connect to database...")
        engine_connect(engine)
        # Try to create session to check if DB is awake
        with Session(engine) as session:
            session.execute(select(1))
    except Exception as e:
        logger.error(e)
        raise e
    logger.info("Database connection successful")


def main() -> None:
    logger.info("Initializing service")
    init()
    with Session(engine) as session:
        init_db(session=session)
