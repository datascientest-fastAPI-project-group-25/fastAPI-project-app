import os
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
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "version": os.environ.get("APP_VERSION", "unknown"),
            "environment": settings.ENVIRONMENT,
        },
    )

@app.get("/health/readiness", tags=["Health"], status_code=status.HTTP_200_OK)
async def readiness_check():
    """Readiness check for orchestration systems like Kubernetes."""
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "status": "ready",
            "timestamp": datetime.now().isoformat(),
        },
    )

@app.get("/health/liveness", tags=["Health"], status_code=status.HTTP_200_OK)
async def liveness_check():
    """Liveness check for orchestration systems like Kubernetes."""
    return JSONResponse(
        status_code=status.HTTP_200_OK,
        content={
            "status": "alive",
            "timestamp": datetime.now().isoformat(),
        },
    )

app.include_router(api_router, prefix=settings.API_V1_STR)
