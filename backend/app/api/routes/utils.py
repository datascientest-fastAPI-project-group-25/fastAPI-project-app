from typing import Any

from fastapi import APIRouter, Depends
from pydantic.networks import EmailStr
from sqlalchemy import text

from app.api.deps import get_current_active_superuser
from app.core.config import settings
from app.db.session import get_session
from app.models import Message
from app.utils import generate_test_email, send_email

router = APIRouter(prefix="/utils", tags=["utils"])


@router.post(
    "/test-email/",
    dependencies=[Depends(get_current_active_superuser)],
    status_code=201,
)
def test_email(email_to: EmailStr) -> Message:
    """
    Test emails.
    """
    email_data = generate_test_email(email_to=email_to)
    send_email(
        email_to=email_to,
        subject=email_data.subject,
        html_content=email_data.html_content,
    )
    return Message(message="Test email sent")


@router.get("/health-check/")
async def health_check() -> dict[str, Any]:
    """
    Health check endpoint that returns system status.
    """
    try:
        # Add database connection check
        with next(get_session()) as db:
            db.execute(text("SELECT 1"))

        return {
            "status": "healthy",
            "service": {
                "name": settings.PROJECT_NAME,
                "version": "1.0.0",
                "environment": settings.ENVIRONMENT,
            },
            "system": {"database": "connected", "dependencies": "healthy"},
        }
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
