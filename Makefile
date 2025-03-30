# DevOps Demo Application Makefile
# This Makefile simplifies common development tasks

# Default target
.DEFAULT_GOAL := help

# Variables
PYTHON_VERSION := 3.11
BACKEND_DIR := backend
FRONTEND_DIR := frontend
DOCKER_COMPOSE := docker compose

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
	@echo "  make setup-hooks        Setup git hooks with pre-commit"
	@echo ""
	@echo "Development Commands:"
	@echo "  make dev                Run the application in development mode"
	@echo "  make stop               Stop all services"
	@echo "  make restart            Restart all services"
	@echo "  make logs               View logs from all services"
	@echo "  make backend-logs       View backend service logs"
	@echo "  make frontend-logs      View frontend service logs"
	@echo ""
	@echo "Testing Commands:"
	@echo "  make test               Run all tests"
	@echo "  make test-backend       Run backend tests"
	@echo "  make test-frontend      Run frontend tests"
	@echo "  make test-e2e          Run end-to-end tests"
	@echo "  make test-integration   Run integration tests"
	@echo "  make test-hooks         Test git hooks locally"
	@echo ""
	@echo "CI/CD and Workflow Testing:"
	@echo "  make ci                 Run full CI pipeline (lint, test, security)"
	@echo "  make cd                 Run full CD pipeline (build, deploy)"
	@echo "  make test-workflow      Test GitHub workflow interactively"
	@echo "  make test-workflow-params workflow=FILE event=TYPE  Test specific workflow"
	@echo ""
	@echo "Code Quality Commands:"
	@echo "  make lint               Run all linting checks"
	@echo "  make format             Format all code"
	@echo "  make security-scan      Run security scanning and audits"
	@echo ""
	@echo "Database Commands:"
	@echo "  make db-init            Initialize the database"
	@echo "  make db-migrate         Run database migrations"
	@echo "  make db-reset           Reset the database (WARNING: destroys data)"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  make clean              Remove build artifacts and cache files"
	@echo "  make clean-docker       Remove Docker containers and volumes"
	@echo "  make clean-all          Remove all generated files and Docker resources"

#################################################
# Setup and Installation                        #
#################################################
set-permissions: ## Set correct permissions for scripts
	@echo "🔧 Setting script permissions..."
	@chmod +x $(BACKEND_DIR)/scripts/*.sh
	@echo "✨ Script permissions set!"

setup: env install set-permissions ## Setup the complete project environment
	@echo "✨ Project setup complete!"

install: ## Install all project dependencies
	@echo "🔧 Installing dependencies..."
	@$(DOCKER_COMPOSE) build
	@echo "✨ Dependencies installed!"

env: ## Generate a secure .env file from .env.example
	@if [ ! -f .env ] && [ -f .env.example ]; then \
		cp .env.example .env; \
		echo "🔒 Generated .env file from .env.example"; \
		echo "⚠️  Please update the .env file with your secure credentials!"; \
	else \
		echo "⚠️  .env file already exists or .env.example not found"; \
	fi

#################################################
# Development Commands                          #
#################################################
dev: ## Run the application in development mode
	@echo "🚀 Starting development environment..."
	@$(DOCKER_COMPOSE) up -d
	@echo "✨ Development environment is running!"
	@echo "📝 Access the services at:"
	@echo "   Frontend: http://dashboard.localhost"
	@echo "   Backend:  http://api.localhost"
	@echo "   Docs:     http://api.localhost/docs"

stop: ## Stop all services
	@echo "🛑 Stopping all services..."
	@$(DOCKER_COMPOSE) down
	@echo "✨ All services stopped!"

restart: stop set-permissions dev ## Restart all services

logs: ## View logs from all services
	@$(DOCKER_COMPOSE) logs -f

backend-logs: ## View backend service logs
	@$(DOCKER_COMPOSE) logs -f backend

frontend-logs: ## View frontend service logs
	@$(DOCKER_COMPOSE) logs -f frontend

#################################################
# Testing Commands                              #
#################################################
test: test-backend test-frontend test-e2e test-integration ## Run all tests

test-backend: ## Run backend tests
	@echo "🧪 Running backend tests..."
	@$(DOCKER_COMPOSE) exec -T backend pytest /app/backend/tests/unit -v

test-frontend: ## Run frontend tests
	@echo "🧪 Running frontend tests..."
	@$(DOCKER_COMPOSE) exec -T frontend pnpm test

test-e2e: ## Run end-to-end tests
	@echo "🧪 Running end-to-end tests..."
	@$(DOCKER_COMPOSE) run --rm frontend-test

test-integration: ## Run integration tests
	@echo "🧪 Running integration tests..."
	@$(DOCKER_COMPOSE) exec -T backend pytest /app/backend/tests/integration -v

#################################################
# CI/CD and Hooks Testing                      #
#################################################
ci: lint test security-scan ## Run full CI pipeline

cd: ci ## Run full CD pipeline (includes CI)
	@echo "🚀 Running CD pipeline..."
	@$(DOCKER_COMPOSE) build
	@echo "✨ CD pipeline complete!"

test-hooks: ## Test git hooks locally
	@echo "🔄 Testing git hooks..."
	@pre-commit run --all-files
	@echo "✨ Hook tests complete!"

test-workflow: ## Test a GitHub workflow interactively
	@echo "🔄 Testing GitHub workflow..."
	@echo "Available workflows:"
	@ls -1 .github/workflows/*.yml | sed 's|.github/workflows/||' | nl
	@echo "Enter the number of the workflow to test: "; \
	read workflow_num; \
	workflow=$$(ls -1 .github/workflows/*.yml | sed -n "$$workflow_num p"); \
	if [ -z "$$workflow" ]; then \
		echo "Invalid selection"; \
		exit 1; \
	fi; \
	echo "Select event type:"; \
	echo "1) push"; \
	echo "2) pull_request"; \
	echo "3) workflow_call"; \
	read event_num; \
	case $$event_num in \
		1) event="push";; \
		2) event="pull_request";; \
		3) event="workflow_call";; \
		*) echo "Invalid selection"; exit 1;; \
	esac; \
	make test-workflow-params workflow=$$(basename $$workflow) event=$$event

test-workflow-params: ## Test a specific GitHub workflow
	@if [ -z "$(workflow)" ] || [ -z "$(event)" ]; then \
		echo "⚠️  Usage: make test-workflow-params workflow=<workflow-file> event=<event-type>"; \
		exit 1; \
	fi
	@echo "🔄 Testing workflow $(workflow) with event $(event)..."
	@echo "ℹ️  Note: Some workflows may fail locally due to missing GitHub context:"
	@echo "   - PR workflows: Missing PR title, labels, or review data"
	@echo "   - Branch workflows: Missing branch context or protection rules"
	@echo "   - These failures are expected locally and will work on GitHub"
	@echo ""
	@if [ ! -f ".github/workflows/events/$(event).json" ]; then \
		echo "⚠️  Event file .github/workflows/events/$(event).json not found"; \
		exit 1; \
	fi
	@./scripts/test-workflow.sh .github/workflows/$(workflow) $(event) || ( \
		echo "" && \
		echo "ℹ️  This failure might be expected if the workflow requires GitHub-specific context." && \
		echo "   The workflow will likely succeed on GitHub with proper context." && \
		exit 0 \
	)

test-all-workflows: ## Test all GitHub workflows with appropriate events
	@echo "🔄 Testing all workflows..."
	@echo "ℹ️  Note: Some workflows may fail locally due to missing GitHub context"
	@echo "   These failures are expected and the workflows will work on GitHub"
	@echo ""
	@(\
		set -e; \
		make test-workflow-params workflow=branch-protection.yml event=pull_request; \
		make test-workflow-params workflow=linting.yml event=workflow_call; \
		make test-workflow-params workflow=tests.yml event=workflow_call; \
		make test-workflow-params workflow=formatting.yml event=workflow_call; \
		make test-workflow-params workflow=dev-branch-checks.yml event=push; \
		make test-workflow-params workflow=merge-to-main.yml event=pull_request; \
		make test-workflow-params workflow=merge-to-stg.yml event=pull_request; \
		make test-workflow-params workflow=pr-to-main.yml event=push; \
		make test-workflow-params workflow=pr-to-stg-creation.yml event=push; \
		make test-workflow-params workflow=approve-pr.yml event=pull_request; \
		make test-workflow-params workflow=automerge.yml event=pull_request; \
		echo "✅ All workflows tested successfully!"\
	)

setup-hooks: ## Setup git hooks with pre-commit
	@echo "🔧 Setting up git hooks..."
	@git config --unset-all core.hooksPath || true
	@pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
	@echo "✨ Git hooks setup complete!"

#################################################
# Code Quality Commands                         #
#################################################
lint: ## Run all linting checks
	@echo "🔍 Running linting checks..."
	@$(DOCKER_COMPOSE) exec -T backend ruff check /app/backend
	@$(DOCKER_COMPOSE) exec -T frontend pnpm lint
	@echo "✨ Linting complete!"

format: ## Format all code
	@echo "✨ Formatting code..."
	@$(DOCKER_COMPOSE) exec -T backend ruff format /app/backend
	@$(DOCKER_COMPOSE) exec -T frontend pnpm format
	@echo "✨ Formatting complete!"

security-scan: ## Run security scanning and audits
	@echo "🔒 Running security scans..."
	@$(DOCKER_COMPOSE) exec -T backend pip-audit
	@$(DOCKER_COMPOSE) exec -T frontend pnpm audit
	@echo "✨ Security scanning complete!"

#################################################
# Database Commands                            #
#################################################
db-init: ## Initialize the database
	@echo "🗃️  Initializing database..."
	@$(DOCKER_COMPOSE) exec -T backend python /app/backend/app/initial_data.py
	@echo "✨ Database initialized!"

db-migrate: ## Run database migrations
	@echo "🔄 Running database migrations..."
	@$(DOCKER_COMPOSE) exec -T backend alembic upgrade head
	@echo "✨ Migrations complete!"

db-reset: ## Reset the database (WARNING: destroys data)
	@echo "⚠️  WARNING: This will destroy all data in the database!"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ]
	@echo "🗑️  Resetting database..."
	@$(DOCKER_COMPOSE) down -v
	@$(DOCKER_COMPOSE) up -d db
	@$(MAKE) db-migrate
	@$(MAKE) db-init
	@echo "✨ Database reset complete!"

#################################################
# Cleanup Commands                             #
#################################################
clean: ## Remove build artifacts and cache files
	@echo "🧹 Cleaning build artifacts and cache..."
	@find . -type d -name "__pycache__" -exec rm -rf {} +
	@find . -type d -name ".pytest_cache" -exec rm -rf {} +
	@find . -type d -name ".ruff_cache" -exec rm -rf {} +
	@find . -type d -name ".coverage" -exec rm -rf {} +
	@find . -type d -name "node_modules" -exec rm -rf {} +
	@echo "✨ Clean complete!"

clean-docker: ## Remove Docker containers and volumes
	@echo "🧹 Cleaning Docker resources..."
	@$(DOCKER_COMPOSE) down -v
	@echo "✨ Docker cleanup complete!"

clean-all: clean clean-docker ## Remove all generated files and Docker resources

# Mark targets that don't create files
.PHONY: help setup install env dev stop restart logs backend-logs frontend-logs \
        test test-backend test-frontend test-e2e lint format security-scan \
        db-init db-migrate db-reset clean clean-docker clean-all

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
