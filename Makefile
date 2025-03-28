# DevOps Demo Application Makefile
# This Makefile simplifies common development tasks

# Default target
.DEFAULT_GOAL := help

# Variables
PYTHON_VERSION := 3.10
BACKEND_DIR := backend
FRONTEND_DIR := frontend

#################################################
# Help and Documentation                        #
#################################################
# Display help message with available commands
help:
	@echo "DevOps Demo Application Makefile"
	@echo ""
	@echo "Setup Commands:"
	@echo "  make setup              Setup the project (dependencies, env files)"
	@echo "  make install            Install all dependencies"
	@echo "  make env                Generate a secure .env file from .env.example"
	@echo ""
	@echo "Development Commands:"
	@echo "  make run                Run the application locally"
	@echo "  make lint               Run all linting checks"
	@echo "  make format             Format all code"
	@echo "  make clean              Remove build artifacts and cache files"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test               Run all tests"
	@echo "  make test-backend       Run backend tests"
	@echo "  make test-frontend      Run frontend tests"
	@echo "  make test-integration   Run integration tests"
	@echo ""
	@echo "CI/CD Commands:"
	@echo "  make ci                 Run full CI pipeline (lint, test, security)"
	@echo "  make cd                 Run full CD pipeline (build, deploy)"
	@echo "  make security-scan      Run security scanning and audits"
	@echo "  make test-workflow       Test a GitHub workflow with Act (interactive)"
	@echo "  make test-workflow-params event=EVENT workflow=WORKFLOW  Test a specific workflow"
	@echo ""
	@echo "Git Hooks:"
	@echo "  make setup-hooks        Setup git hooks with pre-commit"
	@echo "  make run-hooks          Run pre-commit hooks manually"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make docker-build       Build all Docker images"
	@echo "  make docker-up          Start all Docker containers"
	@echo "  make docker-down        Stop all Docker containers"

#################################################
# Setup and Installation                        #
#################################################
# Setup the complete project environment
setup: install env setup-hooks
	@echo " Project setup complete!"

# Install all project dependencies
install: backend-install frontend-install
	@echo " All dependencies installed!"

# Generate a secure .env file from .env.example
env:
	@echo " Generating .env file from .env.example..."
	@if [ ! -f .env ] && [ -f .env.example ]; then \
		cp .env.example .env; \
		echo " .env file created from .env.example"; \
	else \
		echo "  .env file already exists or .env.example not found"; \
	fi

#################################################
# Backend Commands                              #
#################################################
# Install backend dependencies
backend-install:
	@echo " Installing backend dependencies..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make docker-up' to start the containers."; \
		exit 1; \
	fi
	@echo " Backend dependencies are already installed in the Docker container."
	@echo " If you need to install dependencies locally, run:"
	@echo " cd $(BACKEND_DIR) && python3 -m venv .venv && . .venv/bin/activate && pip install -U pip && pip install uv && uv pip install -e \".[dev,lint,types,test]\""
	@echo " Backend dependencies installed!"

# Run backend linting
backend-lint:
	@echo " Running backend linting..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make docker-up' to start the containers."; \
		exit 1; \
	fi
	docker compose exec backend bash -c "cd /app && ruff check app && ruff format app --check"
	@echo " Backend linting complete!"

# Format backend code
backend-format:
	@echo " Formatting backend code..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make docker-up' to start the containers."; \
		exit 1; \
	fi
	docker compose exec backend bash -c "cd /app && ruff format app"
	@echo " Backend code formatted!"

# Run backend tests
backend-test:
	@echo " Running backend tests..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make docker-up' to start the containers."; \
		exit 1; \
	fi
	docker compose exec backend bash -c "cd /app && pytest --cov=app"
	@echo " Backend tests complete!"

# Run backend security checks
backend-security:
	@echo " Running backend security checks..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make docker-up' to start the containers."; \
		exit 1; \
	fi
	docker compose exec backend bash -c "cd /app && bandit -r app/ && safety check"
	@echo " Backend security checks complete!"

#################################################
# Frontend Commands                             #
#################################################
# Install frontend dependencies
frontend-install:
	@echo " Installing frontend dependencies..."
	cd $(FRONTEND_DIR) && pnpm install --frozen-lockfile
	@echo " Frontend dependencies installed!"

# Run frontend linting
frontend-lint:
	@echo " Running frontend linting..."
	cd $(FRONTEND_DIR) && pnpm run lint && pnpm run format:check
	@echo " Frontend linting complete!"

# Format frontend code
frontend-format:
	@echo " Formatting frontend code..."
	cd $(FRONTEND_DIR) && pnpm run format
	@echo " Frontend code formatted!"

# Run frontend tests
frontend-test:
	@echo " Running frontend tests..."
	cd $(FRONTEND_DIR) && pnpm run test
	@echo " Frontend tests complete!"

# Run frontend security checks
frontend-security:
	@echo " Running frontend security checks..."
	cd $(FRONTEND_DIR) && pnpm audit
	@echo " Frontend security checks complete!"

#################################################
# Combined Commands                             #
#################################################
# Run all linting checks
lint: backend-lint frontend-lint
	@echo " All linting checks complete!"

# Format all code
format: backend-format frontend-format
	@echo " All code formatting complete!"

# Run all tests
test: test-backend test-frontend test-integration
	@echo " All tests complete!"

# Run backend tests
test-backend: backend-test

# Run frontend tests
test-frontend: frontend-test

# Run integration tests
test-integration:
	@echo " Running integration tests..."
	@echo " Integration tests not yet implemented"

# Run security scanning and audits
security-scan: backend-security frontend-security
	@echo " All security checks complete!"

# Run full CI pipeline
ci: lint test security-scan
	@echo " CI pipeline complete!"

# Run full CD pipeline
cd: ci docker-build
	@echo " CD pipeline complete!"

#################################################
# Docker Commands                               #
#################################################
# Build all Docker images
docker-build:
	@echo " Building Docker images..."
	docker compose build
	@echo " Docker images built!"

# Start all Docker containers
docker-up:
	@echo " Starting Docker containers..."
	docker compose up -d
	@echo " Docker containers started!"

# Stop all Docker containers
docker-down:
	@echo " Stopping Docker containers..."
	docker compose down
	@echo " Docker containers stopped!"

#################################################
# Git Hooks                                     #
#################################################
# Setup git hooks with pre-commit
setup-hooks:
	@echo " Setting up git hooks with pre-commit..."
	@node scripts/setup-precommit.js
	@echo " Git hooks setup complete!"

# Run pre-commit hooks manually
run-hooks:
	@echo " Running pre-commit hooks..."
	@pre-commit run --all-files
	@echo " Pre-commit hooks check complete!"

#################################################
# GitHub Workflows                              #
#################################################

# Validate GitHub Actions workflows
validate-workflows:
	@echo " Validating GitHub Actions workflows..."
	@for file in .github/workflows/**/*.yml; do \
		echo "Validating $$file..."; \
		yamlvalidator $$file || echo "  Validation issues in $$file"; \
	done
	@echo " Workflow validation complete!"

# Test GitHub Actions workflows locally
workflow-test-image:
	@echo " Building workflow test Docker image..."
	docker build -t local/workflow-test:latest -f .github/workflows/utils/Dockerfile.workflow-test .
	@echo " Workflow test Docker image built successfully!"

# Test a GitHub workflow with Act (interactive)
test-workflow: workflow-test-image
	@echo " Testing GitHub workflow..."
	node scripts/test-workflow-selector.js
	@echo " Workflow testing complete!"

# Test a specific workflow with Act
test-workflow-params: workflow-test-image
	@echo " Testing specific GitHub workflow..."
	./scripts/test-workflow.sh .github/workflows/$(workflow) $(event)
	@echo " Specific workflow testing complete!"

# Test all GitHub workflows
test-all-workflows: workflow-test-image
	@echo " Testing all GitHub workflows..."
	@echo " Testing feature workflows..."
	@make test-workflow-params event=push workflow=feature-push.yml || echo "Feature workflow test failed"
	@echo " Testing formatting workflows..."
	@make test-workflow-params event=push workflow=formatting.yml || echo "Formatting workflow test failed"
	@echo " Testing linting workflows..."
	@make test-workflow-params event=push workflow=linting.yml || echo "Linting workflow test failed"
	@echo " Testing dev workflows..."
	@make test-workflow-params event=push workflow=merge-to-dev.yml || echo "Dev workflow test failed"
	@make test-workflow-params event=pull_request workflow=pr-to-dev.yml || echo "Dev PR workflow test failed"
	@echo " Testing stg workflows..."
	@make test-workflow-params event=push workflow=merge-to-stg.yml || echo "Stg workflow test failed"
	@make test-workflow-params event=pull_request workflow=pr-to-stg.yml || echo "Stg PR workflow test failed"
	@echo " All workflow tests complete!"

#################################################
# Cleanup                                       #
#################################################
# Clean up project artifacts and cache files
clean:
	@echo " Cleaning up project..."
	rm -rf $(BACKEND_DIR)/.venv
	rm -rf $(FRONTEND_DIR)/node_modules
	rm -rf $(BACKEND_DIR)/__pycache__
	rm -rf $(BACKEND_DIR)/app/__pycache__
	rm -rf $(BACKEND_DIR)/.pytest_cache
	rm -rf $(BACKEND_DIR)/.coverage
	rm -rf $(BACKEND_DIR)/coverage.xml
	rm -rf $(FRONTEND_DIR)/coverage
	@echo " Cleanup complete!"

#################################################
# PHONY Targets                                 #
#################################################
.PHONY: help setup install env \
        backend-install backend-lint backend-format backend-test backend-security \
        frontend-install frontend-lint frontend-format frontend-test frontend-security \
        lint format test test-backend test-frontend test-integration \
        security-scan ci cd \
        docker-build docker-up docker-down \
        setup-hooks run-hooks \
        test-workflow test-workflow-params validate-workflows \
        clean test-app-local test-app-ci

# Run tests in local mode
test-app-local:
	@echo " Running tests in local mode..."
	@node scripts/test-app.js local $(TEST_ARGS)
	@echo " Tests completed successfully!"

# Run tests in CI mode
test-app-ci:
	@echo " Running tests in CI mode..."
	@node scripts/test-app.js ci $(TEST_ARGS)
	@echo " Tests completed successfully!"
