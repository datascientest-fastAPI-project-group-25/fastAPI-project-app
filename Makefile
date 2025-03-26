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
help:
	@echo "DevOps Demo Application Makefile "
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
	@echo "  make test-workflow-params category=CATEGORY event=EVENT [workflow=WORKFLOW]  Test a specific workflow"
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
setup: install env setup-hooks
	@echo " Project setup complete!"

install: backend-install frontend-install
	@echo " All dependencies installed!"

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
backend-install:
	@echo " Installing backend dependencies..."
	cd $(BACKEND_DIR) && python3 -m pip install uv && uv venv && . .venv/bin/activate && uv pip install -e ".[dev,lint,types,test]"
	@echo " Backend dependencies installed!"

backend-lint:
	@echo " Running backend linting..."
	cd $(BACKEND_DIR) && source .venv/bin/activate && ruff check app && ruff format app --check
	@echo " Backend linting complete!"

backend-format:
	@echo " Formatting backend code..."
	cd $(BACKEND_DIR) && source .venv/bin/activate && ruff format app
	@echo " Backend code formatted!"

backend-test:
	@echo " Running backend tests..."
	cd $(BACKEND_DIR) && source .venv/bin/activate && pytest --cov=app
	@echo " Backend tests complete!"

backend-security:
	@echo " Running backend security checks..."
	cd $(BACKEND_DIR) && source .venv/bin/activate && bandit -r app/ && safety check
	@echo " Backend security checks complete!"

#################################################
# Frontend Commands                             #
#################################################
frontend-install:
	@echo " Installing frontend dependencies..."
	cd $(FRONTEND_DIR) && pnpm install --frozen-lockfile
	@echo " Frontend dependencies installed!"

frontend-lint:
	@echo " Running frontend linting..."
	cd $(FRONTEND_DIR) && pnpm run lint && pnpm run format:check
	@echo " Frontend linting complete!"

frontend-format:
	@echo " Formatting frontend code..."
	cd $(FRONTEND_DIR) && pnpm run format
	@echo " Frontend code formatted!"

frontend-test:
	@echo " Running frontend tests..."
	cd $(FRONTEND_DIR) && pnpm run test
	@echo " Frontend tests complete!"

frontend-security:
	@echo " Running frontend security checks..."
	cd $(FRONTEND_DIR) && pnpm audit
	@echo " Frontend security checks complete!"

#################################################
# Combined Commands                             #
#################################################
lint: backend-lint frontend-lint
	@echo " All linting checks complete!"

format: backend-format frontend-format
	@echo " All code formatting complete!"

test: test-backend test-frontend
	@echo " All tests complete!"

test-backend: backend-test
test-frontend: frontend-test

test-integration:
	@echo " Running integration tests..."
	@echo " Integration tests not yet implemented"

security-scan: backend-security frontend-security
	@echo " All security checks complete!"

ci: lint test security-scan
	@echo " CI pipeline complete!"

cd: ci docker-build
	@echo " CD pipeline complete!"

#################################################
# Docker Commands                               #
#################################################
docker-build:
	@echo " Building Docker images..."
	docker compose build
	@echo " Docker images built!"

docker-up:
	@echo " Starting Docker containers..."
	docker compose up -d
	@echo " Docker containers started!"

docker-down:
	@echo " Stopping Docker containers..."
	docker compose down
	@echo " Docker containers stopped!"

#################################################
# Git Hooks                                     #
#################################################
setup-hooks:
	@echo " Setting up git hooks with pre-commit..."
	@node scripts/setup-precommit.js
	@echo " Git hooks setup complete!"

run-hooks:
	@echo " Running pre-commit hooks..."
	@pre-commit run --all-files
	@echo " Pre-commit hooks check complete!"

#################################################
# GitHub Workflows                              #
#################################################

validate-workflows:
	@echo " Validating GitHub Actions workflows..."
	@for file in .github/workflows/**/*.yml; do \
		echo "Validating $$file..."; \
		yamlvalidator $$file || echo "  Validation issues in $$file"; \
	done
	@echo " Workflow validation complete!"

test-workflow:
	@echo " Testing GitHub workflow (interactive)..."
	@node scripts/test-workflow-selector.js
	@echo " Workflow testing complete!"

test-workflow-params:
	@echo " Testing GitHub workflow with parameters..."
	@if [ -z "$(category)" ] || [ -z "$(event)" ]; then \
		echo "Error: Required parameters missing. Usage: make test-workflow-params category=CATEGORY event=EVENT [workflow=WORKFLOW]"; \
		exit 1; \
	fi
	@if [ -z "$(workflow)" ]; then \
		act $(event) -W .github/workflows/$(category)/ --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
			--env-file .env \
			--env PROJECT_NAME=FastAPI \
			--env POSTGRES_SERVER=localhost \
			--env POSTGRES_USER=postgres \
			--env FIRST_SUPERUSER=admin@example.com \
			--env FIRST_SUPERUSER_PASSWORD=password; \
	else \
		act $(event) -W .github/workflows/$(category)/$(workflow) --platform ubuntu-latest=ghcr.io/catthehacker/ubuntu:act-latest \
			--env-file .env \
			--env PROJECT_NAME=FastAPI \
			--env POSTGRES_SERVER=localhost \
			--env POSTGRES_USER=postgres \
			--env FIRST_SUPERUSER=admin@example.com \
			--env FIRST_SUPERUSER_PASSWORD=password; \
	fi
	@echo " Workflow testing complete!"

test-all-workflows:
	@echo " Testing all GitHub workflows..."
	@echo " Testing feature workflows..."
	@make test-workflow-params category=feature event=push workflow=feature-push.yml || echo "Feature workflow test failed"
	@echo " Testing pre-commit workflows..."
	@make test-workflow-params category=pre-commit event=push workflow=pre-commit.yml || echo "Pre-commit workflow test failed"
	@echo " Testing dev workflows..."
	@make test-workflow-params category=dev event=push workflow=merge-to-dev.yml || echo "Dev workflow test failed"
	@make test-workflow-params category=dev event=pull_request workflow=pr-to-dev.yml || echo "Dev PR workflow test failed"
	@echo " Testing main workflows..."
	@make test-workflow-params category=main event=push workflow=merge-to-main.yml || echo "Main workflow test failed"
	@make test-workflow-params category=main event=pull_request workflow=pr-to-main.yml || echo "Main PR workflow test failed"
	@echo " All workflow tests complete!"

#################################################
# Cleanup                                       #
#################################################
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

test-workflow:
	@echo " Testing GitHub workflow with Act..."
	@node scripts/test-workflow-selector.js
	@echo " Workflow test complete!"

test-workflow-params:
	@echo " Testing GitHub workflow with Act using parameters..."
	@node scripts/test-workflow-selector.js --category "$(category)" --event "$(event)" $(if $(workflow),--workflow "$(workflow)",)
	@echo " Workflow test complete!"

test-app-local:
	@echo " Running tests in local mode..."
	@node scripts/test-app.js local $(TEST_ARGS)
	@echo " Tests completed successfully!"

test-app-ci:
	@echo " Running tests in CI mode..."
	@node scripts/test-app.js ci $(TEST_ARGS)
	@echo " Tests completed successfully!"
