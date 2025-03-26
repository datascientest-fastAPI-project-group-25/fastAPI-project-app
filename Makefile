# DevOps Demo Application Makefile
# This Makefile simplifies common development tasks

# Default target
.DEFAULT_GOAL := help

# Variables
PYTHON_VERSION := 3.8
BACKEND_DIR := backend/

# Help target
help:
	@echo "DevOps Demo Application Makefile 🚀"
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

# Setup targets
setup:
	@echo "Setting up the project..."
	# Add setup commands here

# Linting targets
lint: lint-and-format
	@echo "Running linting..."

lint-and-format:
	@echo "Running linting and formatting..."
	@docker compose exec -w /app/backend backend bash -c "source /app/.venv/bin/activate && ruff check . && ruff format ."
	@echo "✅ Backend linting and formatting complete."
	@echo "Running frontend linting and formatting..."
	cd frontend && pnpm run lint && pnpm run format:check
	@echo "✅ Frontend linting and formatting complete."

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

# Backend commands
backend-install:
	@echo "🔧 Installing backend dependencies..."
	cd $(BACKEND_DIR) && python3 -m pip install uv && uv venv && . .venv/bin/activate && uv pip install -e ".[dev,lint,types,test]"
	@echo "✅ Backend dependencies installed!"

backend-lint:
	@echo "🔍 Running backend linting..."
	cd $(BACKEND_DIR) && source .venv/bin/activate && ruff check app && ruff format app --check
	@echo "✅ Backend linting complete!"

backend-format:
	@echo "✏️ Formatting backend code..."
	cd $(BACKEND_DIR) && source .venv/bin/activate && ruff format app
	@echo "✅ Backend code formatted!"

# Frontend commands
frontend-install:
	@echo "🔧 Installing frontend dependencies..."
	cd frontend && pnpm install --frozen-lockfile
	@echo "✅ Frontend dependencies installed!"

frontend-lint:
	@echo "🔍 Running frontend linting..."
	cd frontend && pnpm run lint && pnpm run format:check
	@echo "✅ Frontend linting complete!"

frontend-format:
	@echo "✏️ Formatting frontend code..."
	cd frontend && pnpm run format
	@echo "✅ Frontend code formatted!"

frontend-test:
	@echo "🔍 Running frontend tests..."
	cd frontend && pnpm run test
	@echo "✅ Frontend tests complete!"

# Combined commands
install: backend-install frontend-install
test: backend-test frontend-test
security-scan: backend-security frontend-security
format: backend-format frontend-format

# Cleanup
clean:
	rm -rf backend/.venv
	rm -rf frontend/node_modules
	rm -rf backend/__pycache__
	rm -rf backend/app/__pycache__
	rm -rf backend/.pytest_cache
	rm -rf backend/.coverage
	rm -rf backend/coverage.xml
	rm -rf frontend/coverage

.PHONY: help setup env up down restart init-db test test-backend test-frontend test-frontend-ci \
        feat fix fix-automerge clean build lint setup-playwright check-login \
        backend-lint frontend-build-docker act-test act-test-main act-test-protection \
        act-test-all act-test-dry-run act-test-job ci cd security-scan validate-workflows deploy \
        setup-hooks run-hooks validate-hooks install lint test security-scan format clean \
        backend-install backend-lint backend-format backend-test backend-security \
        frontend-install frontend-lint frontend-format frontend-test frontend-security \
        lint-and-format
