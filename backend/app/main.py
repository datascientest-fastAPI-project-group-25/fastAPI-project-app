import sentry_sdk
import logging
import time
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.routing import APIRoute
from prometheus_fastapi_instrumentator import Instrumentator # Added for Prometheus
from prometheus_client import Counter, Histogram

from app.api.main import api_router
from app.core.config import settings
from app.logging_config import setup_logging


def custom_generate_unique_id(route: APIRoute) -> str:
    if route.tags and len(route.tags) > 0:
        return f"{route.tags[0]}-{route.name}"
    return route.name


# Setup logging
setup_logging()
logger = logging.getLogger("app")

if settings.SENTRY_DSN and settings.ENVIRONMENT != "local":
    sentry_sdk.init(dsn=str(settings.SENTRY_DSN), enable_tracing=True)

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url="/openapi.json",
    docs_url="/docs",
    redoc_url="/redoc",
    generate_unique_id_function=custom_generate_unique_id,
)

# Define metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration',
    ['method', 'endpoint']
)

# Add metrics middleware
@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    http_requests_total.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()

    http_request_duration_seconds.labels(
        method=request.method,
        endpoint=request.url.path
    ).observe(duration)

    return response

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

# Instrument the app for Prometheus metrics
Instrumentator().instrument(app).expose(app)

app.include_router(api_router, prefix=settings.API_V1_STR)

# Add startup event to log application startup
@app.on_event("startup")
def startup_event():
    logger.info("Application started")

# Add structured logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    logger.info(
        "Request processed",
        extra={
            "method": request.method,
            "path": request.url.path,
            "duration": duration,
            "status_code": response.status_code
        }
    )
    return response


