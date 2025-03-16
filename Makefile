# DevOps Demo Application Makefile
# This Makefile simplifies common development tasks

.PHONY: help setup env up down restart init-db test test-backend test-frontend feat fix fix-automerge clean build lint check-login

# Default target
help:
	@echo "DevOps Demo Application Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make setup              Setup the project (create .env, install dependencies)"
	@echo "  make env                Generate a secure .env file from .env.example"
	@echo ""
	@echo "Docker & pnpm:"
	@echo "  make up                 Start Docker containers with pnpm and Traefik"
	@echo "  make down               Stop Docker containers"
	@echo "  make restart            Restart Docker containers"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test               Run all tests"
	@echo "  make test-backend       Run backend tests"
	@echo "  make test-frontend      Run frontend tests"
	@echo "  make check-login        Test login functionality"
	@echo ""
	@echo "pnpm Monorepo Commands:"
	@echo "  make build              Build all workspaces using pnpm"
	@echo "  make lint               Run linting across all workspaces"
	@echo ""
	@echo "Git Workflow:"
	@echo "  make feat name=branch-name     Create a new feature branch"
	@echo "  make fix name=branch-name      Create a new fix branch"
	@echo "  make fix-automerge name=branch-name  Create a fix branch with automerge"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean              Clean up temporary files and directories"

# Setup the project
setup: env up
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

# Start Docker containers with pnpm for faster builds
up: 
	@echo "Starting Docker containers with pnpm..."
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
	@echo ""
	@echo "Validating login functionality..."
	@sleep 5
	@$(MAKE) check-login

# Initialize the database (create tables and first superuser)
init-db:
	@echo "Initializing database..."
	docker compose exec backend python /app/scripts/init_db.py
	@echo "Database initialization complete."

# Stop Docker containers
down:
	@echo "Stopping Docker containers..."
	docker compose down --remove-orphans

# Restart Docker containers
restart: down up

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
	@echo "Cleanup complete!"

# pnpm commands for monorepo management
# ----------------------------------------

# Build all workspaces
build:
	@echo "Building all workspaces using pnpm..."
	@docker compose up -d frontend backend
	@docker compose exec frontend sh -c "cd /app && pnpm -r build"
	@docker compose exec backend sh -c "cd /app && pip install -e ."
	@echo "All builds complete."

# Run linting across all workspaces
lint:
	@echo "Running linting across all workspaces..."
	@docker compose up -d frontend backend
	@docker compose exec frontend sh -c "cd /app && pnpm -r lint"
	@echo "Linting complete."

# Setup Playwright for testing
setup-playwright:
	@echo "Setting up Playwright..."
	@docker compose run --rm frontend sh ./setup-playwright.sh
	@echo "Playwright setup complete."

# Test login functionality
check-login:
	@echo "Testing login functionality..."
	@python test_login.py http://api.localhost
	@echo "Login test complete."

# Run backend linting
backend-lint:
	@echo "Running backend linting..."
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
