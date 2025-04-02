from sqlmodel import Session, create_engine, select

from app.core.config import settings
from app.core.security import get_password_hash
from app.models import User
from app.schemas import UserCreate

# Create database URL
database_url = str(settings.SQLALCHEMY_DATABASE_URI)

# Create async engine
engine = create_engine(
    database_url,
    echo=settings.ENVIRONMENT == "local",
    connect_args={"check_same_thread": False}
    if database_url.startswith("sqlite")
    else {},
)


def engine_connect(engine) -> None:
    """Test database connection."""
    with engine.connect() as conn:
        conn.execute(select(1))
        # Explicitly commit the transaction to avoid warnings
        conn.commit()


def init_db(session: Session) -> None:
    """Initialize database with first superuser."""
    user = session.exec(
        select(User).where(User.email == settings.FIRST_SUPERUSER)
    ).first()
    if not user:
        user_in = UserCreate(
            email=settings.FIRST_SUPERUSER,
            password=settings.FIRST_SUPERUSER_PASSWORD,
            is_superuser=True,
            full_name="Initial Super User",
        )
        user = User(
            email=user_in.email,
            hashed_password=get_password_hash(user_in.password),
            is_superuser=user_in.is_superuser,
            is_active=True,
            full_name=user_in.full_name,
        )
        session.add(user)
        session.commit()
        session.refresh(user)
