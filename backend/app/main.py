import os
import time
from datetime import datetime

import sentry_sdk
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.routing import APIRoute

from app.api.main import api_router
from app.core.config import settings


def custom_generate_unique_id(route: APIRoute) -> str:
    return f"{route.tags[0]}-{route.name}"


if settings.SENTRY_DSN and settings.ENVIRONMENT != "local":
    sentry_sdk.init(dsn=str(settings.SENTRY_DSN), enable_tracing=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    generate_unique_id_function=custom_generate_unique_id,
)

# Define specific origins that are allowed to access the API
origins = [
    "http://localhost",
    "http://localhost:5173",
    "http://127.0.0.1",
    "http://127.0.0.1:5173",
    "http://127.0.0.1:50686",  # Browser preview tool
    "http://dashboard.localhost",
    "http://api.localhost",
]

# Add CORS middleware with specific origins and credentials support
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,  # Allow credentials for authenticated requests
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allow_headers=["*"],
    expose_headers=["*"],
)

# Add health check endpoints directly to the main app (no authentication required)
@app.get("/health", tags=["Health"], status_code=status.HTTP_200_OK)
async def health_check():
    """Basic health check endpoint for monitoring and orchestration systems."""
    try:
        # Basic health check information
        health_data = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "version": os.environ.get("APP_VERSION", "unknown"),
            "environment": settings.ENVIRONMENT,
            "git_hash": os.environ.get("GIT_HASH", "unknown"),
        }
        
        # Try to get system metrics if psutil is available
        try:
            import psutil
            memory_usage = psutil.virtual_memory().percent
            cpu_usage = psutil.cpu_percent(interval=0.1)
            # Use a fixed, safe path for disk usage check
            safe_path = os.path.abspath(os.sep)
            disk_usage = psutil.disk_usage(safe_path).percent

            # Check if resource usage is within acceptable limits
            resource_status = "healthy"
            if memory_usage > 90 or cpu_usage > 90 or disk_usage > 90:
                resource_status = "degraded"

            # Add system metrics to the response
            health_data["system"] = {
                "status": resource_status,
                "memory_usage_percent": memory_usage,
                "cpu_usage_percent": cpu_usage,
                "disk_usage_percent": disk_usage,
            }
        except ImportError:
            # If psutil is not available, just provide basic health check
            health_data["system"] = {
                "status": "unknown",
                "message": "Detailed system metrics not available (psutil not installed)",
            }

        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content=health_data,
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={
                "status": "unhealthy",
                "timestamp": datetime.now().isoformat(),
                "error": str(e),
            },
        )

@app.get("/health/readiness", tags=["Health"], status_code=status.HTTP_200_OK)
async def readiness_check():
    """Readiness check for orchestration systems like Kubernetes.
    
    Verifies if the application is ready to handle traffic.
    """
    try:
        # Check database connectivity
        from app.db.session import engine
        from sqlalchemy import text as sql_text
        
        db_status = "error"
        with engine.connect() as connection:
            result = connection.execute(sql_text("SELECT 1"))
            if result.scalar() == 1:
                db_status = "connected"

        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "status": "ready",
                "timestamp": datetime.now().isoformat(),
                "database": db_status,
                "dependencies": {
                    "database": db_status == "connected"
                }
            },
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "not ready",
                "timestamp": datetime.now().isoformat(),
                "error": str(e),
                "dependencies": {
                    "database": False
                }
            },
        )

@app.get("/health/liveness", tags=["Health"], status_code=status.HTTP_200_OK)
async def liveness_check():
    """Liveness check for orchestration systems like Kubernetes.
    
    Verifies if the application is running and not deadlocked.
    """
    try:
        liveness_data = {
            "status": "alive",
            "timestamp": datetime.now().isoformat(),
            "process_id": os.getpid(),
        }
        
        # Try to get uptime if psutil is available
        try:
            import psutil
            uptime_seconds = int(time.time() - psutil.boot_time())
            liveness_data["uptime_seconds"] = uptime_seconds
        except ImportError:
            liveness_data["uptime"] = "unknown (psutil not installed)"
        
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content=liveness_data,
        )
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "not alive",
                "timestamp": datetime.now().isoformat(),
                "error": str(e),
            },
        )

app.include_router(api_router, prefix=settings.API_V1_STR)
