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
	@echo "  make test               Run all tests (backend, frontend, e2e, integration)"
	@echo "  make test-backend       Run backend tests (Python/pytest)"
	@echo "  make test-backend TEST_PATH=path/to/test.py  Run specific backend tests"
	@echo "  make test-specific TEST_PATH=path/to/test.py Run specific backend tests with verbose output"
	@echo "  make test-frontend      Run frontend tests (JavaScript/TypeScript with Vitest)"
	@echo "  make test-e2e           Run end-to-end tests (simulates user interactions)"
	@echo "  make test-integration   Run integration tests (tests API endpoints and database)"
	@echo "  make test-hooks         Test git hooks locally"
	@echo "  make test-coverage      Run all tests with code coverage reporting"
	@echo "  make test-backend-coverage  Run backend tests with code coverage reporting"
	@echo "  make test-frontend-coverage Run frontend tests with code coverage reporting"
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

install: ## Install all dependencies
	@echo "🔧 Installing dependencies..."
	@$(DOCKER_COMPOSE) exec -T backend uv venv
	@$(DOCKER_COMPOSE) exec -T backend uv pip install -e .
	@$(DOCKER_COMPOSE) exec -T backend uv pip install pytest
	@$(DOCKER_COMPOSE) exec -T backend uv pip install ruff
	@$(DOCKER_COMPOSE) exec -T backend uv pip install python-jose[cryptography]
	@$(DOCKER_COMPOSE) exec -T backend uv run ruff check /app/backend
	@$(DOCKER_COMPOSE) exec -T frontend npm install -g typescript@latest
	@$(DOCKER_COMPOSE) exec -T frontend pnpm install
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
	@echo "🗃️  Checking if database initialization is needed..."
	@sleep 10 # Give backend and database time to start
	@$(DOCKER_COMPOSE) exec -T backend bash -c "if command -v uv >/dev/null 2>&1; then \
		if ! uv run python /app/backend/app/db/check_db.py; then \
			echo '🗃️  Database needs initialization, running db-init...'; \
			exit 1; \
		fi; \
	else \
		echo 'UV not available, skipping database check'; \
		exit 1; \
	fi" || $(MAKE) db-init
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
# This section contains commands for running tests.
#
# Test Types:
# - Backend Tests: Python tests for the backend API using pytest
#   - Unit Tests: Tests for individual functions and classes
#   - Integration Tests: Tests for API endpoints and database interactions
#   - Coverage Tests: Tests with code coverage reporting
#
# - Frontend Tests: JavaScript/TypeScript tests for the frontend using Vitest
#   - Unit Tests: Tests for individual components and functions
#   - Coverage Tests: Tests with code coverage reporting
#
# - End-to-End Tests: Tests that simulate user interactions with the complete application
#
# Requirements:
# - Docker containers must be running (will be started automatically if not running)
# - Python and pytest must be available for backend tests (will be installed if not available)
# - Node.js and pnpm must be available for frontend tests (will be installed if not available)
#################################################
test: ## Run all tests (backend, frontend, e2e, integration)
	@echo "🧪 Running all tests (backend, frontend, e2e, integration)..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@$(MAKE) install

	@echo "📋 Checking for test files in all directories..."
	@BACKEND_TESTS=$$($(DOCKER_COMPOSE) exec -T backend bash -c "find tests -name \"test_*.py\" | wc -l"); \
	FRONTEND_TESTS=$$($(DOCKER_COMPOSE) exec -T frontend bash -c "find . -name \"*.test.ts\" -o -name \"*.test.tsx\" -o -name \"*.spec.ts\" -o -name \"*.spec.tsx\" | wc -l"); \
	echo "Found $$BACKEND_TESTS backend test files and $$FRONTEND_TESTS frontend test files"; \
	if [ "$$BACKEND_TESTS" -eq 0 ]; then \
		echo "⚠️ Warning: No backend test files found"; \
	fi; \
	if [ "$$FRONTEND_TESTS" -eq 0 ]; then \
		echo "⚠️ Warning: No frontend test files found"; \
	fi; \
	if [ "$$BACKEND_TESTS" -eq 0 ] && [ "$$FRONTEND_TESTS" -eq 0 ]; then \
		echo "❌ Error: No test files found in any directory"; \
		exit 1; \
	fi

	@echo "🧪 Running all tests..."
	@BACKEND_EXIT=0; \
	FRONTEND_EXIT=0; \
	E2E_EXIT=0; \
	INTEGRATION_EXIT=0; \

	@echo "🧪 Running backend tests..."; \
	$(MAKE) test-backend || BACKEND_EXIT=$$?; \

	@echo "🧪 Running frontend tests..."; \
	$(MAKE) test-frontend || FRONTEND_EXIT=$$?; \

	@echo "🧪 Running e2e tests..."; \
	$(MAKE) test-e2e || E2E_EXIT=$$?; \

	@echo "🧪 Running integration tests..."; \
	$(MAKE) test-integration || INTEGRATION_EXIT=$$?; \

	@echo ""; \
	echo "📊 Overall Test Summary:"; \
	echo "======================"; \
	if [ $$BACKEND_EXIT -eq 0 ]; then \
		echo "✅ Backend tests: PASSED"; \
	else \
		echo "❌ Backend tests: FAILED (exit code: $$BACKEND_EXIT)"; \
	fi; \

	if [ $$FRONTEND_EXIT -eq 0 ]; then \
		echo "✅ Frontend tests: PASSED"; \
	else \
		echo "❌ Frontend tests: FAILED (exit code: $$FRONTEND_EXIT)"; \
	fi; \

	if [ $$E2E_EXIT -eq 0 ]; then \
		echo "✅ E2E tests: PASSED"; \
	else \
		echo "❌ E2E tests: FAILED (exit code: $$E2E_EXIT)"; \
	fi; \

	if [ $$INTEGRATION_EXIT -eq 0 ]; then \
		echo "✅ Integration tests: PASSED"; \
	else \
		echo "❌ Integration tests: FAILED (exit code: $$INTEGRATION_EXIT)"; \
	fi; \

	if [ $$BACKEND_EXIT -ne 0 ] || [ $$FRONTEND_EXIT -ne 0 ] || [ $$E2E_EXIT -ne 0 ] || [ $$INTEGRATION_EXIT -ne 0 ]; then \
		echo ""; \
		echo "❌ Some tests failed. Please check the output above for details."; \
		exit 1; \
	else \
		echo ""; \
		echo "✨ All tests passed successfully!"; \
	fi

test-backend: ## Run backend tests (Python/pytest)
	@echo "🧪 Running backend tests (Python/pytest)..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if UV is available..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "if ! command -v uv >/dev/null 2>&1; then \
		echo '❌ UV is not available. Please check your Docker setup.'; \
		exit 1; \
	fi"
	@echo "📦 Installing pytest..."
	@$(DOCKER_COMPOSE) exec -T backend uv pip install pytest

	@echo "🔍 Checking for test files..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "\
		UNIT_TESTS=\$$(find tests/unit -name \"test_*.py\" | wc -l); \
		INTEGRATION_TESTS=\$$(find tests/integration -name \"test_*.py\" | wc -l); \
		API_TESTS=\$$(find tests/api -name \"test_*.py\" | wc -l); \
		CRUD_TESTS=\$$(find tests/crud -name \"test_*.py\" | wc -l); \
		echo \"Found \$$UNIT_TESTS unit tests, \$$INTEGRATION_TESTS integration tests, \$$API_TESTS API tests, \$$CRUD_TESTS CRUD tests\"; \
		TOTAL_TESTS=\$$((UNIT_TESTS + INTEGRATION_TESTS + API_TESTS + CRUD_TESTS)); \
		if [ \"\$$TOTAL_TESTS\" -eq 0 ]; then \
			echo \"⚠️ Warning: No test files found in any test directory\"; \
		fi"

	@echo "🧪 Running tests..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "\
		set +e; \
		if [ -n \"$(TEST_PATH)\" ]; then \
			echo \"Running specific tests: $(TEST_PATH)\"; \
			uv run pytest $(TEST_PATH) -v | tee test_output.log; \
		else \
			echo \"Running all tests\"; \
			uv run pytest tests -v | tee test_output.log; \
		fi; \
		TEST_EXIT_CODE=\$$?; \
		FAILURES=\$$(grep -c \"FAILED\" test_output.log || true); \
		WARNINGS=\$$(grep -c \"warning\" test_output.log || true); \
		echo \"\"; \
		echo \"📊 Test Summary:\"; \
		echo \"===================\"; \
		if [ \$$TEST_EXIT_CODE -ne 0 ]; then \
			echo \"❌ Tests: FAILED (\$$FAILURES failures, \$$WARNINGS warnings)\"; \
		else \
			echo \"✅ Tests: PASSED (with \$$WARNINGS warnings)\"; \
		fi; \
		if [ \$$WARNINGS -gt 0 ]; then \
			echo \"⚠️ Warnings detected in tests. Check the output above for details.\"; \
		fi; \
		exit \$$TEST_EXIT_CODE"
	@echo "🧪 Backend tests complete!"

test-specific: ## Run specific backend tests (usage: make test-specific TEST_PATH=tests/path/to/test.py)
	@echo "🧪 Running specific backend tests: $(TEST_PATH)"
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if UV is available..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "if ! command -v uv >/dev/null 2>&1; then \
		echo '❌ UV is not available. Please check your Docker setup.'; \
		exit 1; \
	fi"
	@echo "📦 Installing pytest..."
	@$(DOCKER_COMPOSE) exec -T backend uv pip install pytest
	@$(DOCKER_COMPOSE) exec -T backend uv run pytest $(TEST_PATH) -v
	@echo "🧪 Specific tests complete!"

test-frontend: ## Run frontend tests (JavaScript/TypeScript with Vitest)
	@echo "🧪 Running frontend tests (JavaScript/TypeScript with Vitest)..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if frontend dependencies are installed..."
	@$(DOCKER_COMPOSE) exec -T frontend bash -c "if ! command -v pnpm >/dev/null 2>&1; then \
		echo '📦 Installing frontend dependencies...'; \
		exit 1; \
	fi" || $(MAKE) install

	@echo "🔍 Checking for frontend test files..."
	@$(DOCKER_COMPOSE) exec -T frontend bash -c "\
		UNIT_TESTS=\$$(find . -name \"*.test.ts\" -o -name \"*.test.tsx\" -o -name \"*.spec.ts\" -o -name \"*.spec.tsx\" | wc -l); \
		echo \"Found \$$UNIT_TESTS frontend test files\"; \
		if [ \"\$$UNIT_TESTS\" -eq 0 ]; then \
			echo \"⚠️ Warning: No frontend test files found\"; \
		fi"

	@echo "🧪 Running frontend tests..."
	@$(DOCKER_COMPOSE) exec -T frontend bash -c "\
		set +e; \
		pnpm test | tee test_output.log; \
		TEST_EXIT_CODE=\$$?; \
		FAILURES=\$$(grep -c \"FAIL\" test_output.log || true); \
		WARNINGS=\$$(grep -c \"warning\" test_output.log || true); \
		echo \"\"; \
		echo \"📊 Frontend Test Summary:\"; \
		echo \"===================\"; \
		if [ \$$TEST_EXIT_CODE -ne 0 ]; then \
			echo \"❌ Tests: FAILED (\$$FAILURES failures, \$$WARNINGS warnings)\"; \
		else \
			echo \"✅ Tests: PASSED (with \$$WARNINGS warnings)\"; \
		fi; \
		if [ \$$WARNINGS -gt 0 ]; then \
			echo \"⚠️ Warnings detected in tests. Check the output above for details.\"; \
		fi; \
		exit \$$TEST_EXIT_CODE"
	@echo "🧪 Frontend tests complete!"

test-coverage: ## Run all tests with code coverage reporting
	@echo "📊 Running all tests with code coverage reporting..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@$(MAKE) install
	@$(MAKE) test-backend-coverage
	@$(MAKE) test-frontend-coverage
	@echo "📊 All coverage tests complete!"

test-backend-coverage: ## Run backend tests with code coverage reporting
	@echo "📊 Running backend tests with code coverage reporting..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if UV is available..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "if ! command -v uv >/dev/null 2>&1; then \
		echo '❌ UV is not available. Please check your Docker setup.'; \
		exit 1; \
	fi"
	@echo "📦 Installing pytest and coverage..."
	@$(DOCKER_COMPOSE) exec -T backend uv pip install pytest coverage pytest-cov
	@$(DOCKER_COMPOSE) exec -T backend uv run pytest --cov=app --cov-report=term --cov-report=html
	@echo "📊 Backend coverage tests complete! HTML report available in backend/htmlcov/"

test-frontend-coverage: ## Run frontend tests with code coverage reporting
	@echo "📊 Running frontend tests with code coverage reporting..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if frontend dependencies are installed..."
	@$(DOCKER_COMPOSE) exec -T frontend bash -c "if ! command -v pnpm >/dev/null 2>&1; then \
		echo '📦 Installing frontend dependencies...'; \
		exit 1; \
	fi" || $(MAKE) install
	@$(DOCKER_COMPOSE) exec -T frontend sh -c "cd /app/frontend && pnpm test:coverage"
	@echo "📊 Frontend coverage tests complete!"

test-e2e: ## Run end-to-end tests (simulates user interactions with the complete application)
	@echo "🧪 Running end-to-end tests (simulates user interactions with the complete application)..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if frontend dependencies are installed..."
	@$(DOCKER_COMPOSE) exec -T frontend bash -c "if ! command -v pnpm >/dev/null 2>&1; then \
		echo '📦 Installing frontend dependencies...'; \
		exit 1; \
	fi" || $(MAKE) install

	@echo "🔍 Checking for e2e test files..."
	@$(DOCKER_COMPOSE) exec -T frontend bash -c "\
		E2E_TESTS=\$$(find tests -name \"*.spec.ts\" | wc -l); \
		echo \"Found \$$E2E_TESTS e2e test files\"; \
		if [ \"\$$E2E_TESTS\" -eq 0 ]; then \
			echo \"⚠️ Warning: No e2e test files found\"; \
		fi"

	@echo "🧪 Running e2e tests..."
	@$(DOCKER_COMPOSE) run --rm frontend-test | tee e2e_test_output.log; \
	TEST_EXIT_CODE=$$?; \
	FAILURES=$$(grep -c "FAIL\|ERROR" e2e_test_output.log || true); \
	WARNINGS=$$(grep -c "warning" e2e_test_output.log || true); \
	echo ""; \
	echo "📊 E2E Test Summary:"; \
	echo "==================="; \
	if [ $$TEST_EXIT_CODE -ne 0 ]; then \
		echo "❌ Tests: FAILED ($$FAILURES failures, $$WARNINGS warnings)"; \
	else \
		echo "✅ Tests: PASSED (with $$WARNINGS warnings)"; \
	fi; \
	if [ $$WARNINGS -gt 0 ]; then \
		echo "⚠️ Warnings detected in tests. Check the output above for details."; \
	fi; \
	echo "🧪 End-to-end tests complete!"; \
	exit $$TEST_EXIT_CODE

test-integration: ## Run integration tests (tests API endpoints and database interactions)
	@echo "🧪 Running integration tests (tests API endpoints and database interactions)..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "🚀 Docker containers are not running. Starting them..."; \
		$(MAKE) dev; \
	fi
	@echo "🔍 Checking if UV is available..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "if ! command -v uv >/dev/null 2>&1; then \
		echo '❌ UV is not available. Please check your Docker setup.'; \
		exit 1; \
	fi"
	@echo "📦 Installing pytest..."
	@$(DOCKER_COMPOSE) exec -T backend uv pip install pytest

	@echo "🔍 Checking for integration test files..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "\
		INTEGRATION_TESTS=\$$(find tests/integration -name \"test_*.py\" | wc -l); \
		echo \"Found \$$INTEGRATION_TESTS integration test files\"; \
		if [ \"\$$INTEGRATION_TESTS\" -eq 0 ]; then \
			echo \"⚠️ Warning: No integration test files found in tests/integration directory\"; \
		fi"

	@echo "🧪 Running integration tests..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "\
		set +e; \
		uv run pytest /app/backend/tests/integration -v | tee integration_test_output.log; \
		TEST_EXIT_CODE=\$$?; \
		FAILURES=\$$(grep -c \"FAILED\" integration_test_output.log || true); \
		WARNINGS=\$$(grep -c \"warning\" integration_test_output.log || true); \
		echo \"\"; \
		echo \"📊 Integration Test Summary:\"; \
		echo \"===================\"; \
		if [ \$$TEST_EXIT_CODE -ne 0 ]; then \
			echo \"❌ Tests: FAILED (\$$FAILURES failures, \$$WARNINGS warnings)\"; \
		else \
			echo \"✅ Tests: PASSED (with \$$WARNINGS warnings)\"; \
		fi; \
		if [ \$$WARNINGS -gt 0 ]; then \
			echo \"⚠️ Warnings detected in tests. Check the output above for details.\"; \
		fi; \
		exit \$$TEST_EXIT_CODE"
	@echo "🧪 Integration tests complete!"

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
	@./scripts/test-workflow.sh .github/workflows/$(workflow) $(event)

test-all-workflows: ## Test all GitHub workflows with appropriate events
	@echo "🔄 Testing all workflows..."
	@echo "ℹ️  Note: Some workflows may fail locally due to missing GitHub context"
	@echo "   However, we will now report these failures to ensure they are addressed"
	@echo ""
	@(\
		set -e; \
		FAILED=0; \
		for workflow_event in \
			"branch-protection.yml:pull_request" \
			"linting.yml:workflow_call" \
			"tests.yml:workflow_call" \
			"formatting.yml:workflow_call" \
			"dev-branch-checks.yml:push" \
			"merge-to-main.yml:pull_request" \
			"merge-to-stg.yml:pull_request" \
			"pr-to-main.yml:push" \
			"pr-to-stg-creation.yml:push" \
			"approve-pr.yml:pull_request" \
			"automerge.yml:pull_request"; \
		do \
			IFS=: read -r workflow event <<< "$$workflow_event"; \
			echo "🔄 Testing workflow: $$workflow with event: $$event"; \
			if ! make test-workflow-params workflow=$$workflow event=$$event; then \
				echo "❌ Workflow $$workflow failed with event $$event"; \
				FAILED=1; \
			else \
				echo "✅ Workflow $$workflow passed with event $$event"; \
			fi; \
			echo ""; \
		done; \
		if [ $$FAILED -eq 0 ]; then \
			echo "✅ All workflows tested successfully!"; \
			exit 0; \
		else \
			echo "❌ Some workflows failed. Please check the output above."; \
			exit 1; \
		fi \
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
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make dev' to start the containers."; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec -T backend bash -c "command -v uv >/dev/null 2>&1 && (uv pip install ruff && uv run ruff check /app/backend) || echo 'UV not available, skipping backend linting'"
	@$(DOCKER_COMPOSE) exec -T frontend pnpm lint
	@echo "✨ Linting complete!"

format: ## Format all code
	@echo "✨ Formatting code..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make dev' to start the containers."; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec -T backend bash -c "command -v uv >/dev/null 2>&1 && (uv pip install ruff && uv run ruff format /app/backend) || echo 'UV not available, skipping backend formatting'"
	@$(DOCKER_COMPOSE) exec -T frontend pnpm format
	@echo "✨ Formatting complete!"

security-scan: ## Run security scanning and audits
	@echo "🔒 Running security scans..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make dev' to start the containers."; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec -T backend bash -c "command -v uv >/dev/null 2>&1 && uv pip audit || echo 'UV not available, skipping backend security scanning'"
	@$(DOCKER_COMPOSE) exec -T frontend pnpm audit
	@echo "✨ Security scanning complete!"

#################################################
# Database Commands                            #
#################################################
db-init: ## Initialize the database
	@echo "🗃️  Initializing database..."
	@$(DOCKER_COMPOSE) exec -T backend bash -c "command -v uv >/dev/null 2>&1 && uv run python /app/backend/app/initial_data.py || echo 'UV not available, skipping database initialization'"
	@echo "✨ Database initialized!"

db-migrate: ## Run database migrations
	@echo "🔄 Running database migrations..."
	@if ! $(DOCKER_COMPOSE) ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make dev' to start the containers."; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec -T backend bash -c "command -v uv >/dev/null 2>&1 && (uv pip install alembic && uv run alembic upgrade head) || echo 'UV not available, skipping database migrations'"
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
        test test-backend test-frontend test-e2e test-specific test-integration \
        test-coverage test-backend-coverage test-frontend-coverage \
        test-hooks test-workflow test-workflow-params test-all-workflows setup-hooks \
        ci cd lint format security-scan \
        db-init db-migrate db-reset clean clean-docker clean-all \
        backend-format backend-security \
        frontend-install frontend-lint frontend-format frontend-security

# Format backend code
backend-format:
	@echo " Formatting backend code..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make dev' to start the containers."; \
		exit 1; \
	fi
	docker compose exec backend bash -c "cd /app && command -v uv >/dev/null 2>&1 && (uv pip install ruff && uv run ruff format app) || echo 'UV not available, skipping backend formatting'"
	@echo " Backend code formatted!"

# Run backend security checks
backend-security:
	@echo " Running backend security checks..."
	@if ! docker compose ps -q | grep -q .; then \
		echo "Error: Docker containers are not running. Please run 'make dev' to start the containers."; \
		exit 1; \
	fi
	docker compose exec backend bash -c "cd /app && command -v uv >/dev/null 2>&1 && (uv pip install bandit safety && uv run bandit -r app/ && uv run safety check) || echo 'UV not available, skipping backend security checks'"
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

# Run frontend security checks
frontend-security:
	@echo " Running frontend security checks..."
	cd $(FRONTEND_DIR) && pnpm audit
	@echo " Frontend security checks complete!"

#################################################
# Combined Commands                             #
#################################################
# Format all code
