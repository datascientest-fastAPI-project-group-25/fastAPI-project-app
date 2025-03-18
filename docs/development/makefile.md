# Makefile System Documentation

This document describes the Makefile system used in our project for managing development, testing, deployment, and maintenance tasks.

## Overview

**The Makefile is the central interface for all aspects of our project.** It serves as the primary and recommended way to interact with the codebase throughout its entire lifecycle - from initial setup and development to testing, deployment, and maintenance.

All team members should use the Makefile commands for consistency, rather than running individual tools directly. This ensures that everyone follows the same workflows and processes, reducing errors and improving productivity.

The Makefile system is organized into several sections, each handling a specific aspect of the project:

- Core Development
- Security
- Testing
- Accessibility
- CI/CD
- Documentation
- Docker Management
- Environment Management
- Maintenance

## Directory Structure

```
make/
├── Makefile              # Main Makefile with core targets and includes
├── variables.mk          # Shared variables and help text
├── security.mk           # Security-related targets
├── testing.mk            # Testing-related targets
├── accessibility.mk      # Accessibility-related targets
├── ci.mk                 # CI/CD-related targets
├── maintenance.mk        # Maintenance-related targets
├── documentation.mk      # Documentation-related targets
├── docker.mk             # Docker-related targets
└── environment.mk        # Environment-related targets
```

## Core Development Targets

### Project Setup

- `make start` - Initial setup after cloning the repository
- `make branch` - Create a new branch using the interactive CLI
- `make install` - Install all dependencies (backend and frontend)
- `make dev` - Start development mode with hot reload

### Code Quality

- `make format-backend` - Format backend code using Black
- `make format-frontend` - Format frontend code using Prettier
- `make format-all` - Format all code (backend and frontend)
- `make lint-backend` - Lint backend code using Ruff
- `make lint-frontend` - Lint frontend code using ESLint
- `make lint-all` - Lint all code (backend and frontend)
- `make style-backend` - Style check backend code
- `make style-frontend` - Style check frontend code
- `make style-all` - Style check all code
- `make pretty` - Run all formatting, linting, and style checks

## Security Targets

- `make security-backend` - Security check backend using Bandit
- `make security-frontend` - Security check frontend using npm audit
- `make security-all` - Security check all code
- `make security-scan` - Run comprehensive security scan

## Testing Targets

- `make test-unit-backend` - Run backend unit tests
- `make test-unit-frontend` - Run frontend unit tests
- `make test-unit-all` - Run all unit tests
- `make test-integration` - Run integration tests
- `make test-e2e` - Run end-to-end tests
- `make test-coverage` - Generate test coverage report

## Accessibility Targets

- `make a11y-audit` - Run accessibility audit
- `make a11y-lighthouse` - Run Lighthouse performance checks
- `make a11y-wcag` - Run WCAG compliance checks
- `make a11y-report` - Generate accessibility report

## CI/CD Targets

- `make ci-validate` - Run pre-commit checks
- `make ci-build` - Run full CI pipeline locally
- `make ci-test` - Run CI test suite

### GitHub Actions Workflow Testing

- `make act-test` - Show available GitHub Actions workflow tests
- `make act-test-main` - Test main-branch.yml workflow
- `make act-test-protection` - Test branch-protection.yml workflow
- `make act-test-all` - Test all workflows
- `make act-test-dry-run` - Dry run of workflows (no execution)
- `make act-test-job` - Test specific job in a workflow (usage: `make act-test-job workflow=main-branch.yml job=lint event=pull_request`)

## Documentation Targets

- `make docs` - Generate all documentation (API, frontend, backend, architecture)
- `make docs-api` - Generate API documentation using pdoc
- `make docs-frontend` - Generate frontend documentation
- `make docs-backend` - Generate backend documentation
- `make docs-architecture` - Generate architecture documentation
- `make docs-serve` - Serve documentation locally
- `make docs-validate` - Validate documentation
- `make docs-clean` - Clean generated documentation

## Docker Management Targets

- `make docker-build` - Build all Docker containers
- `make docker-build-frontend` - Build frontend container
- `make docker-build-backend` - Build backend container
- `make docker-push` - Push all containers to registry
- `make docker-push-frontend` - Push frontend container
- `make docker-push-backend` - Push backend container
- `make docker-pull` - Pull all containers from registry
- `make docker-pull-frontend` - Pull frontend container
- `make docker-pull-backend` - Pull backend container
- `make docker-prune` - Clean up Docker system
- `make docker-logs` - Show Docker container logs
- `make docker-stats` - Show Docker container stats
- `make docker-shell` - Open shell in specified container

## Environment Management Targets

- `make env-dev` - Setup development environment
- `make env-staging` - Setup staging environment
- `make env-prod` - Setup production environment
- `make env-switch` - Switch between environments
- `make env-validate` - Validate environment configuration
- `make env-secrets` - Generate environment secrets
- `make env-backup` - Backup environment files
- `make env-restore` - Restore environment from backup

## Maintenance Targets

- `make clean` - Clean temporary files
- `make prune` - Clean Docker, Node, and Python artifacts
- `make update` - Update all dependencies

## Common Workflows

### Starting a New Feature

```bash
make branch  # Create a new feature branch
make install # Install dependencies
make dev     # Start development server
```

### Running Tests

```bash
make test-unit-all    # Run all unit tests
make test-integration # Run integration tests
make test-e2e        # Run end-to-end tests
```

### Code Quality Checks

```bash
make pretty          # Run all formatting and linting
make security-all    # Run security checks
make a11y-audit      # Run accessibility checks
```

### Documentation

```bash
make docs           # Generate all documentation
make docs-serve     # Serve documentation locally
```

### Docker Operations

```bash
make docker-build   # Build containers
make docker-push    # Push to registry
make docker-prune   # Clean up Docker system
```

### CI/CD Workflow Testing

```bash
make act-test           # Show available workflow tests
make act-test-dry-run   # Dry run of workflows without execution
make act-test-main      # Test main branch workflow
make act-test-job workflow=main-branch.yml job=lint event=pull_request  # Test specific job
```

## Best Practices

1. **Always use the Makefile** for all project tasks rather than running individual tools directly
2. Always run `make pretty` before committing changes
3. Run `make test-unit-all` before pushing changes
4. Use `make branch` to create new branches
5. Keep dependencies updated with `make update`
6. Clean up regularly with `make prune`
7. Test GitHub Actions workflows locally with `make act-test-*` commands before pushing to GitHub
8. Use `make act-test-job` for testing specific jobs when debugging workflow issues

## Troubleshooting

1. If a target fails, check the error message and dependencies
2. Use `make clean` to remove temporary files
3. For Docker issues, try `make docker-prune`
4. For environment issues, use `make env-validate`

## Contributing

When adding new targets:

1. Add the target to the appropriate section file
2. Add help text in `variables.mk`
3. Update this documentation
4. Test the new target using `scripts/test_makefile.sh`

### Backend Commands

- `make backend-lint` - Run backend linting using Ruff
