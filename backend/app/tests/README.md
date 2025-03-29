# Testing Strategy

This document outlines the testing strategy for the FastAPI project application.

## Overview

We are transitioning from integration tests with API calls to unit tests using testing-library with Vitest for better isolation and faster test execution. This approach provides several benefits:

1. **Faster Test Execution**: Unit tests run much faster than integration tests
2. **Better Isolation**: Tests are isolated from external dependencies
3. **Easier Debugging**: When tests fail, it's easier to identify the cause
4. **Improved Test Coverage**: Easier to achieve high test coverage
5. **Better CI/CD Integration**: Faster feedback in the CI/CD pipeline
6. **More Reliable Tests**: Less flakiness due to external dependencies

## Test Directory Structure

```
tests/
├── integration/        # Legacy integration tests (being phased out)
│   └── test_integration.py
├── unit/               # New unit tests (preferred approach)
│   ├── test_user_routes.py
│   └── test_user_service.py
└── README.md           # This file
```

## Backend Testing

### Unit Tests

Unit tests focus on testing individual components in isolation:

- **Service/Logic Tests**: Test business logic with mocked dependencies
  - Located in `tests/unit/test_user_service.py`
  - Tests CRUD operations with mocked database sessions
  - Validates business logic without database access

- **API Route Tests**: Test API routes with mocked database and services
  - Located in `tests/unit/test_user_routes.py`
  - Uses FastAPI's TestClient with dependency overrides
  - Mocks database and service dependencies

- **Model Tests**: Test data models and validation
  - Validates model constraints and relationships
  - Tests schema validation and conversion

### Running Backend Tests

```bash
# Run all unit tests
pytest app/tests/unit/

# Run with coverage
pytest app/tests/unit/ --cov=app --cov-report=xml
```

## Frontend Testing

### Unit Tests with Vitest

We use Vitest with testing-library for frontend unit tests:

- **Component Tests**: Test React components in isolation
  - Located in `src/components/*/*.test.tsx`
  - Tests component rendering and behavior
  - Uses testing-library queries and user interactions

- **API Integration Tests**: Test API interactions with MSW
  - Located in `src/components/ApiExample/UserApi.test.tsx`
  - Uses Mock Service Worker to mock API responses
  - Tests loading, success, and error states

- **Hook Tests**: Test custom React hooks
  - Tests hook behavior and state changes
  - Uses `renderHook` from testing-library

- **Utility Tests**: Test utility functions
  - Pure function testing with simple inputs and outputs

### Running Frontend Tests

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:coverage
```

## CI/CD Integration

Tests are automatically run in the CI/CD pipeline:

1. **GitHub Actions Workflow**: The `tests.yml` workflow runs both backend and frontend tests
2. **Pre-commit Hooks**: Tests are run before commits to ensure code quality
3. **Pull Request Validation**: Tests must pass before a PR can be merged

## Best Practices

1. **Mock External Dependencies**: Always mock external dependencies like databases and APIs
   - Use `unittest.mock` for Python tests
   - Use MSW for frontend API mocking

2. **Test Behavior, Not Implementation**: Focus on testing what components do, not how they do it
   - Test outputs for given inputs
   - Avoid testing implementation details

3. **Keep Tests Fast**: Avoid slow tests that will discourage running the test suite
   - Use in-memory databases for integration tests
   - Mock time-consuming operations

4. **Maintain Test Independence**: Tests should not depend on each other
   - Reset state between tests
   - Use setup and teardown functions

5. **Use Descriptive Test Names**: Test names should describe what is being tested
   - Follow the pattern: `test_<what>_<expected_outcome>`
   - Example: `test_create_user_with_valid_data_returns_user`

6. **Follow Testing Library Best Practices**:
   - Use semantic queries (`getByRole`, `getByLabelText`) over test IDs
   - Use `userEvent` over `fireEvent` for user interactions
   - Test from the user's perspective

## Environment Variables for Testing

The following environment variables are required for tests to run successfully:

```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/test_db
PROJECT_NAME=FastAPI
POSTGRES_SERVER=localhost
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
FIRST_SUPERUSER=admin@example.com
FIRST_SUPERUSER_PASSWORD=password
```
