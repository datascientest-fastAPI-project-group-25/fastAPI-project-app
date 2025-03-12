# GitHub Directory Structure

This document outlines the consolidated structure for the `.github` directory and explains the organization of GitHub Actions workflows.

## Directory Structure

```
.github/
├── workflows/
│   ├── branch/                # Branch-specific workflows
│   │   ├── feature.yml        # Feature branch checks
│   │   ├── dev.yml            # Development branch workflows
│   │   └── main.yml           # Main branch workflows
│   ├── deploy/                # Deployment workflows
│   │   ├── staging.yml        # Staging deployment
│   │   └── production.yml     # Production deployment
│   ├── testing/               # Testing workflows
│   │   ├── backend.yml        # Backend tests
│   │   ├── frontend.yml       # Frontend tests
│   │   ├── integration.yml    # Integration tests
│   │   └── e2e.yml            # End-to-end tests
│   ├── ci/                    # CI utilities
│   │   ├── lint.yml           # Linting workflows
│   │   ├── security.yml       # Security scanning
│   │   └── generate-client.yml # API client generation
│   └── _shared/               # Reusable components
│       ├── actions.yml        # Reusable actions
│       └── jobs.yml           # Reusable jobs
├── CODEOWNERS                 # Code ownership definitions
├── dependabot.yml             # Dependabot configuration
├── labeler.yml                # PR labeler configuration
└── pull_request_template.md   # PR template
```

## Workflow Organization

### Branch-Based Workflows

These workflows are triggered based on branch activity:

- **feature.yml**: Triggered on pushes to `feat/*` and `fix/*` branches
  - Style checks (black, flake8, eslint, prettier)
  - Security checks (bandit, npm audit, pip-audit)
  - Linting & formatting
  - Unit tests

- **dev.yml**: Triggered on pushes to `dev` branch
  - Minimal test suite (unit, linting, security)
  - Staging deployment

- **main.yml**: Triggered on pushes to `main` branch
  - Complete test suite
  - Security scans
  - Dependency checks

### Deployment Workflows

- **staging.yml**: Deploys to staging environment
  - Triggered by successful `dev` branch workflow
  - Uses AWS ECS for deployment

- **production.yml**: Deploys to production environment
  - Triggered by release tags on `main` branch
  - Uses AWS ECS for deployment

### Testing Workflows

Specialized workflows for different types of tests:

- **backend.yml**: Backend unit and integration tests
- **frontend.yml**: Frontend unit tests
- **integration.yml**: API and service integration tests
- **e2e.yml**: End-to-end tests with Playwright

### CI Utilities

- **lint.yml**: Code linting and formatting checks
- **security.yml**: Security scanning and vulnerability checks
- **generate-client.yml**: Generates TypeScript client from OpenAPI spec

### Shared Components

- **actions.yml**: Reusable GitHub Actions steps
- **jobs.yml**: Reusable job definitions for common tasks

## Implementation Plan

1. Create the new directory structure
2. Migrate existing workflows to the new structure
3. Update workflow references and dependencies
4. Test workflows with `act` to ensure they work correctly
5. Update documentation to reflect the new structure

## Benefits

- **Improved organization**: Workflows are grouped by purpose
- **Better maintainability**: Easier to find and update specific workflows
- **Reduced duplication**: Shared components reduce code duplication
- **Clearer workflow paths**: Branch-based organization matches development workflow
