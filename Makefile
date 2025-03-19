# DevOps Demo Application Makefile
# This Makefile simplifies common development tasks

# Default target
.DEFAULT_GOAL := help

# Help target
help:
	@echo "DevOps Demo Application Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make setup              Setup the project (create .env, install dependencies)"
	@echo "  make env                Generate a secure .env file from .env.example"
	@echo ""
	@echo "Development Setup:"
	@echo "  make setup-hooks        Setup git hooks with pre-commit"
	@echo "  make run-hooks          Run pre-commit hooks manually"
	@echo "  make validate-hooks     Validate pre-commit hook configuration"
	@echo ""
	@echo "CI/CD Workflows:"
	@echo "  make ci                 Run full CI pipeline (lint, test, security)"
	@echo "  make cd                 Run full CD pipeline (build, deploy)"
	@echo "  make security-scan      Run security scanning and audits"
	@echo "  make validate-workflows Validate all GitHub Actions workflows"
	@echo ""
	@echo "Testing & Validation:"
	@echo "  make test               Run all tests"
	@echo "  make test-backend       Run backend tests"
	@echo "  make test-frontend      Run frontend tests with improved reliability"
	@echo "  make test-integration   Run integration tests"
	@echo "  make check-login        Test login functionality"
	@echo ""
	@echo "Docker & pnpm:"
	@echo "  make up                 Start Docker containers with pnpm and Traefik"
	@echo "  make down               Stop Docker containers"
	@echo "  make restart            Restart Docker containers"
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
	@echo "GitHub Actions:"
	@echo "  make act-test           Show available GitHub Actions workflow tests"
	@echo "  make act-test-main      Test main-branch.yml workflow"
	@echo "  make act-test-protection Test branch-protection.yml workflow"
	@echo "  make act-test-all      Test all workflows"
	@echo "  make act-test-dry-run  Dry run of workflows (no execution)"
	@echo "  make act-test-job      Test specific job in a workflow (see usage in Makefile)"
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
	@if command -v python3 > /dev/null && python3 -c "import requests" 2>/dev/null; then \
		$(MAKE) check-login; \
	else \
		echo "Skipping login check (python3 or requests module not available)"; \
	fi

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
test: test-backend test-frontend test-integration

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	@docker-compose -f docker-compose.test.yml up backend-tests --exit-code-from backend-tests

# Run backend tests
test-backend:
	@echo "Running backend tests..."
	docker compose run --rm backend pytest

test-frontend:
	@echo "Running frontend tests..."
	@docker-compose -f docker-compose.test.yml up frontend-test --exit-code-from frontend-test



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
	@docker compose exec frontend sh -c "cd /app && pnpm install && cd frontend && pnpm run lint"
	@docker compose exec backend bash -c "source /app/.venv/bin/activate && uv pip install -e '.[dev]' && ruff check app"
	@echo "Linting complete."

# Run backend linting
backend-lint:
	@echo "Running backend linting..."
	@docker compose up -d backend
	@docker compose exec backend bash -c "source /app/.venv/bin/activate && uv pip install -e '.[dev]' && ruff check app"
	@echo "Backend linting complete."

# Setup Playwright for testing
setup-playwright:
	@echo "Setting up Playwright..."
	@docker compose run --rm frontend sh /app/frontend/setup-playwright.sh
	@echo "Playwright setup complete."

# Test login functionality
check-login:
	@echo "Testing login functionality..."
	@python3 test_login.py http://api.localhost
	@echo "Login test complete."

# Build frontend using Docker multi-stage build
frontend-build-docker:
	@echo "Building frontend via Docker multi-stage build..."
	@docker build --target builder -f frontend/Dockerfile -t frontend-builder .
	@echo "Extracting build artifacts..."
	@docker create --name extract-container frontend-builder
	@docker cp extract-container:/app/frontend/dist ./frontend/dist
	@docker rm extract-container
	@echo "Frontend build complete using Docker."

# Test GitHub Actions workflows locally
act-test:
	@echo "Testing GitHub Actions workflows locally..."
	@echo "Available workflow tests:"
	@echo "  make act-test-main         Test main-branch.yml workflow"
	@echo "  make act-test-protection   Test branch-protection.yml workflow"
	@echo "  make act-test-all          Test all workflows"
	@echo "  make act-test-dry-run      Dry run of all workflows (no execution)"

# Test main-branch.yml workflow
act-test-main:
	@echo "Testing main-branch.yml workflow..."
	@timeout 300 ./scripts/test-workflow.sh main-branch.yml pull_request || echo "Test timed out after 5 minutes"
	@echo "\nTip: If the test fails, try:"
	@echo "1. Running specific jobs: make act-test-job workflow=main-branch.yml job=<job_id>"
	@echo "2. Check if required secrets are set in .secrets file"
	@echo "3. Use --privileged flag if Docker permissions are needed"
	@echo "Main branch workflow test complete."

# Test branch-protection.yml workflow
act-test-protection:
	@echo "Testing branch-protection.yml workflow..."
	@timeout 60 ./scripts/test-workflow.sh branch-protection.yml push || echo "Test timed out after 60 seconds"
	@echo "Branch protection workflow test complete."

# Test all workflows
act-test-all: act-test-main act-test-protection
	@echo "All workflow tests complete."

# Dry run of workflows (shows what would be executed without running)
act-test-dry-run:
	@echo "Performing dry run of workflows..."
	@act -n \
		--eventpath .github/workflows/test-event.json \
		--env GITHUB_TOKEN=test-token
	@echo "Dry run complete."

# Test specific job in a workflow
# Usage: make act-test-job workflow=main-branch.yml job=lint event=pull_request
act-test-job:
	@if [ -z "$(workflow)" ]; then \
		echo "Error: Workflow not specified. Use 'make act-test-job workflow=<workflow-file> job=<job-id> [event=<event-type>]'"; \
		exit 1; \
	fi
	@if [ -z "$(job)" ]; then \
		echo "Error: Job not specified. Use 'make act-test-job workflow=<workflow-file> job=<job-id> [event=<event-type>]'"; \
		exit 1; \
	fi
	@echo "Testing job '$(job)' in workflow '$(workflow)'..."
	@EVENT="$(event)" || "pull_request"; \
	echo "Using event: $$EVENT"; \
	timeout 120 act $$EVENT -W .github/workflows/$(workflow) -j $(job) --verbose || echo "Test timed out after 120 seconds"
	@echo "Job test complete."

# CI Pipeline
ci: lint test security-scan validate-workflows
	@echo "CI pipeline completed successfully!"

# CD Pipeline
cd: build deploy
	@echo "CD pipeline completed successfully!"

# Security scanning
security-scan:
	@echo "Running security scans..."
	@docker compose run --rm backend safety check
	@docker compose run --rm frontend pnpm audit
	@echo "Security scanning complete."

# Validate all workflows
validate-workflows: act-test-all
	@echo "All workflows validated successfully."

# Deploy application
deploy:
	@echo "Deploying application..."
	@if [ -f "./scripts/deploy-app.sh" ]; then \
		./scripts/deploy-app.sh; \
	else \
		echo "No deployment script found. Please create ./scripts/deploy-app.sh"; \
		exit 1; \
	fi

.PHONY: help setup env up down restart init-db test test-backend test-frontend test-frontend-ci \
        feat fix fix-automerge clean build lint setup-playwright check-login \
        backend-lint frontend-build-docker act-test act-test-main act-test-protection \
        act-test-all act-test-dry-run act-test-job ci cd security-scan validate-workflows deploy \
        setup-hooks run-hooks validate-hooks

# Git Hooks Management
setup-hooks:
	@echo "🔧 Setting up git hooks with pre-commit..."
	@./scripts/setup-precommit.sh
	@echo "✅ Git hooks setup complete!"

run-hooks:
	@echo "🔍 Running pre-commit hooks..."
	@pre-commit run --all-files
	@echo "✅ Pre-commit hooks check complete!"

validate-hooks:
	@echo "🔍 Validating pre-commit hook configuration..."
	@pre-commit validate-config
	@pre-commit validate-manifest
	@echo "✅ Pre-commit hook configuration is valid!"
