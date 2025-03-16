# DevOps Demo Application Makefile
# This Makefile simplifies common development tasks

.PHONY: help setup env docker-up docker-down docker-restart init-db test test-backend test-frontend create-feature-branch create-fix-branch create-fix-branch-automerge clean turbo-build turbo-test turbo-lint turbo-clean

# Default target
help:
	@echo "DevOps Demo Application Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make setup              Setup the project (create .env, install dependencies)"
	@echo "  make env                Generate a secure .env file from .env.example"
	@echo ""
	@echo "Fast Build System (pnpm, Traefik, UV):"
	@echo "  make docker-up          Start Docker containers with pnpm and Traefik"
	@echo "  make docker-down        Stop Docker containers"
	@echo "  make docker-restart     Restart Docker containers"
	@echo ""

	@echo "Testing:"
	@echo "  make test               Run all tests"
	@echo "  make test-backend       Run backend tests"
	@echo "  make test-frontend      Run frontend tests"
	@echo ""
	@echo "TurboRepo (Monorepo Management):"
	@echo "  make turbo-build        Build all workspaces using TurboRepo"
	@echo "  make turbo-test         Run tests across all workspaces"
	@echo "  make turbo-lint         Run linting across all workspaces"
	@echo "  make turbo-clean        Clean TurboRepo cache"
	@echo "  make turbo-backend-test Run backend tests using TurboRepo"
	@echo "  make turbo-backend-lint Run backend linting using TurboRepo"
	@echo ""
	@echo "Git Workflow:"
	@echo "  make feat name=branch-name    Create a new feature branch"
	@echo "  make fix name=branch-name        Create a new fix branch"
	@echo "  make fix-auto name=branch-name  Create a fix branch with automerge"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean              Clean up temporary files and directories"

# Setup the project
setup: env docker-up
	@echo "Project setup complete!"

# Generate a secure .env file from .env.example
env:
	@echo "Generating secure .env file from .env.example..."
	@if [ -f .env ]; then \
		echo ".env file already exists. Skipping..."; \
	else \
		cp .env.example .env; \
		SECRET_KEY=$$(openssl rand -hex 32); \
		sed -i '' "s/SECRET_KEY=.*/SECRET_KEY=$$SECRET_KEY/" .env; \
		DB_PASSWORD=$$(openssl rand -base64 12); \
		sed -i '' "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$$DB_PASSWORD/" .env; \
		ADMIN_PASSWORD=$$(openssl rand -base64 12); \
		sed -i '' "s/FIRST_SUPERUSER_PASSWORD=.*/FIRST_SUPERUSER_PASSWORD=$$ADMIN_PASSWORD/" .env; \
		echo "Generated secure .env file with random credentials:"; \
		echo "  - SECRET_KEY: $$SECRET_KEY"; \
		echo "  - DB Password: $$DB_PASSWORD"; \
		echo "  - Admin Password: $$ADMIN_PASSWORD"; \
	fi

# Start Docker containers with Bun for faster builds
docker-up:
	@echo "Starting Docker containers with Bun for faster builds..."
	docker compose up -d
	@echo "Docker containers started. You can access the application at:"
	@echo "  - Frontend: http://dashboard.localhost"
	@echo "  - Backend API: http://api.localhost"
	@echo "  - API Docs: http://api.localhost/docs"
	@echo "  - API ReDoc: http://api.localhost/redoc"
	@echo "  - Traefik Dashboard: http://localhost:8080"
	@echo ""
	@echo "Default login credentials:"
	@echo "  - Email: admin@example.com"
	@echo "  - Password: Check your .env file for FIRST_SUPERUSER_PASSWORD"

# Initialize the database (create tables and first superuser)
init-db:
	@echo "Initializing database..."
	docker compose exec backend python /app/scripts/init_db.py
	@echo "Database initialization complete."

# Stop Docker containers
docker-down:
	@echo "Stopping Docker containers..."
	docker compose down --remove-orphans

# Restart Docker containers
docker-restart: docker-down docker-up

# Run all tests
test: test-backend test-frontend

# Run backend tests
test-backend:
	@echo "Running backend tests..."
	docker compose run --rm backend pytest

# Run frontend tests
test-frontend:
	@echo "Running frontend tests..."
	docker compose run --rm frontend pnpm run test

# Create a new feature branch
feat:
	@if [ -z "$(name)" ]; then \
		echo "Error: Branch name not specified. Use 'make feat name=branch-name'"; \
		exit 1; \
	fi
	@echo "Creating feature branch: feat/$(name)"
	@node ./scripts/create-branch.js --type feat --name $(name)

# Create a new fix branch
fix:
	@if [ -z "$(name)" ]; then \
		echo "Error: Branch name not specified. Use 'make fix name=branch-name'"; \
		exit 1; \
	fi
	@echo "Creating fix branch: fix/$(name)"
	@node ./scripts/create-branch.js --type fix --name $(name)

# Create a new fix branch with automerge
fix-automerge:
	@if [ -z "$(name)" ]; then \
		echo "Error: Branch name not specified. Use 'make fix-automerge name=branch-name'"; \
		exit 1; \
	fi
	@echo "Creating fix branch with automerge: fix/$(name)-automerge"
	@node ./scripts/create-branch.js --type fix --name $(name) --automerge


# Clean up temporary files and directories
clean:
	@echo "Cleaning up temporary files and directories..."
	@find . -name "*.pyc" -delete
	@find . -name "__pycache__" -delete
	@find . -name ".pytest_cache" -delete
	@find . -name ".coverage" -delete
	@find . -name "htmlcov" -delete
	@find . -name "*.egg-info" -delete
	@find . -name "dist" -delete
	@find . -name "build" -delete
	@find . -name "node_modules" -delete
	@find . -name ".turbo" -delete
	@echo "Cleanup complete!"

# TurboRepo commands using Docker and pnpm
# ----------------------------------------

# Separate TypeScript compilation and Vite build into distinct steps
frontend-tsc:
	@echo "Running TypeScript compilation with increased memory..."
	@docker compose exec frontend sh -c "cd /app/frontend && NODE_OPTIONS='--max-old-space-size=8192' pnpm run tsc"
	@echo "TypeScript compilation complete."

frontend-vite:
	@echo "Running Vite build with increased memory..."
	@docker compose exec frontend sh -c "cd /app/frontend && NODE_OPTIONS='--max-old-space-size=8192' pnpm run build"
	@echo "Vite build complete."

# Build backend workspace
backend-build:
	@echo "Building backend workspace..."
	@docker compose up -d backend || { echo "Failed to start backend container"; exit 1; }
	@docker compose exec backend sh -c "cd /app && pip install -e ." || { echo "Backend build failed"; exit 1; }
	@echo "Backend build complete."

# Build all workspaces sequentially to avoid memory issues
turbo-build: frontend-tsc frontend-vite backend-build
	@echo "All builds complete."

# Run tests across all workspaces using TurboRepo
turbo-test: setup-playwright
	@echo "Running tests across all workspaces using TurboRepo..."
	@docker compose up -d frontend backend
	@docker compose exec frontend sh -c "cd /app/frontend && NODE_OPTIONS='--max-old-space-size=2048' pnpm run test"
	@echo "Tests complete."

# Run linting across all workspaces using TurboRepo
turbo-lint:
	@echo "Running linting across all workspaces using TurboRepo..."
	@docker compose up -d frontend backend
	@docker compose exec frontend sh -c "cd /app/frontend && pnpm run lint"
	@echo "Linting complete."

# Setup Playwright for testing
setup-playwright:
	@echo "Setting up Playwright..."
	@docker compose run --rm frontend sh ./setup-playwright.sh
	@echo "Playwright setup complete."

# Clean TurboRepo cache
turbo-clean:
	@echo "Cleaning TurboRepo cache..."
	@docker compose up -d frontend
	@docker compose exec frontend sh -c "cd /app/frontend && pnpm run clean"
	@echo "TurboRepo cache cleaned."

# Run backend-specific tasks using TurboRepo
turbo-backend-test:
	@echo "Running backend tests using TurboRepo..."
	@docker compose up -d backend
	@docker compose exec backend pytest
	@echo "Backend tests complete."

turbo-backend-lint:
	@echo "Running backend linting using TurboRepo..."
	@docker compose up -d backend
	@docker compose exec backend ruff check app tests
	@echo "Backend linting complete."

# Build frontend using Docker multi-stage build
frontend-build-docker:
	@echo "Building frontend via Docker multi-stage build..."
	@docker build --target builder -f frontend/Dockerfile -t frontend-builder .
	@echo "Extracting build artifacts..."
	@docker create --name extract-container frontend-builder
	@docker cp extract-container:/app/frontend/dist ./frontend/dist
	@docker rm extract-container
	@echo "Frontend build complete using Docker."
