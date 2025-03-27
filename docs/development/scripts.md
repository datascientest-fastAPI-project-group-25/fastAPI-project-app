# Development Scripts

This document provides an overview of the utility scripts available in the project. These scripts are designed to streamline common development tasks and ensure consistency across different environments.

## Table of Contents

- [Deployment Scripts](#deployment-scripts)
- [Testing Scripts](#testing-scripts)
- [Development Utility Scripts](#development-utility-scripts)
- [Maintenance Scripts](#maintenance-scripts)

## Deployment Scripts

### `deploy-app.sh`

A unified script for building, pushing, and deploying the application.

**Usage:**

```bash
./scripts/deploy-app.sh [build|push|deploy|all]
```

**Options:**

- `build` - Build Docker images only
- `push` - Build and push Docker images
- `deploy` - Deploy application to Docker Swarm
- `all` - Build, push, and deploy (default if no option provided)

**Required Environment Variables:**

- `TAG`: Docker image tag (required for all operations)
- `DOMAIN`: Domain name (required for deploy operation)
- `STACK_NAME`: Docker stack name (required for deploy operation)
- `FRONTEND_ENV`: Frontend environment (defaults to 'production')

**Example:**

```bash
# Build and push images only
TAG=v1.0.0 ./scripts/deploy-app.sh push

# Full deployment
TAG=v1.0.0 DOMAIN=example.com STACK_NAME=myapp ./scripts/deploy-app.sh all
```

## Testing Scripts

### `test-app.sh`

A unified script for running tests locally or in CI environments.

**Usage:**

```bash
./scripts/test-app.sh [local|ci] [test_args...]
```

**Options:**

- `local` - Run tests in local development environment (default)
- `ci` - Run tests in CI environment

Additional arguments are passed to pytest.

**Environment Variables:**

- `SKIP_CLEANUP`: Set to any value to skip cleanup after tests
- `SKIP_BUILD`: Set to any value to skip Docker build step

**Example:**

```bash
# Run all tests locally
./scripts/test-app.sh local

# Run specific tests with verbose output
./scripts/test-app.sh local -xvs app/tests/api/

# Run tests in CI mode
./scripts/test-app.sh ci
```

## Development Utility Scripts

### `dev-generate-client.sh`

Generates TypeScript client code from OpenAPI specification.

**Usage:**

```bash
./scripts/dev-generate-client.sh
```

**Environment Variables:**

- `SKIP_FORMAT`: Set to any value to skip code formatting

**Example:**

```bash
# Generate client with formatting
./scripts/dev-generate-client.sh

# Generate client without formatting
SKIP_FORMAT=1 ./scripts/dev-generate-client.sh
```

### `feature.sh`

Helps create feature branches following the established branch strategy.

**Usage:**

```bash
./scripts/feature.sh <feature-name>
```

**Example:**

```bash
./scripts/feature.sh add-user-authentication
```

## Maintenance Scripts

### `app-status.sh`

Displays application URLs and login information after startup.

**Usage:**
This script is typically run by the app-status container at the end of startup, but can also be run manually:

```bash
./scripts/app-status.sh
```

### `check-prestart-status.sh`

Verifies database initialization and migrations status.

**Usage:**

```bash
./scripts/check-prestart-status.sh
```

### `test-workflow-selector.js`

Tests GitHub Actions workflows locally with act using an interactive CLI.

**Usage:**
```bash
node scripts/test-workflow-selector.js
```

**Interactive Mode:**
- Select workflow category (e.g., feature, ci)
- Choose specific workflow file
- Select event type (e.g., push, pull_request)

**Non-Interactive Mode:**
```bash
# Test specific workflow
node scripts/test-workflow-selector.js --category=feature --event=push --workflow=feature-branch-checks.yml

# Test all workflows
node scripts/test-workflow-selector.js --all
```

**Prerequisites:**
Before running workflow tests, you need to build the custom Docker image used for testing:

```bash
# Build the workflow test Docker image
docker build -t local/workflow-test:latest -f .github/workflows/utils/Dockerfile.workflow-test .
```

This image contains the necessary tools and dependencies for running GitHub Action workflows locally.

**Example:**
```bash
# Interactive mode
node scripts/test-workflow-selector.js

# Non-interactive mode - specific workflow
node scripts/test-workflow-selector.js --category=feature --event=push --workflow=feature-branch-checks.yml

# Non-interactive mode - all workflows
node scripts/test-workflow-selector.js --all
```

## Best Practices

1. **Environment Variables**: Always set required environment variables before running scripts.
2. **Error Handling**: Pay attention to error messages and exit codes.
3. **Local Testing**: Test changes locally before pushing to feature branches.
4. **CI Integration**: The scripts are designed to work seamlessly in both local and CI environments.

## Troubleshooting

If you encounter issues with any of the scripts:

1. Ensure all dependencies are installed (Docker, Python, Node.js, etc.)
2. Check that environment variables are set correctly
3. Verify that Docker daemon is running
4. Check logs for detailed error messages
