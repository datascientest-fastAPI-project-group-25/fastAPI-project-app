# Scripts Directory

This directory contains utility scripts for the project, organized by functionality.

## Directory Structure

```
scripts/
├── branch/           # Branch management scripts
│   ├── create-branch.ts       # Interactive branch creation CLI
│   ├── feature.sh             # Feature branch creation script
│   └── block-main-push.py     # Git hook to prevent direct pushes to main/dev
├── test/             # Testing scripts
│   ├── test-app.ts            # Test application runner
│   ├── test-workflow.sh       # GitHub workflow tester
│   └── test-workflow-selector.ts # Interactive workflow selector
├── dev/              # Development tools
│   ├── dev-generate-client.sh # API client generator
│   └── setup-precommit.ts     # Pre-commit hooks setup
├── ci/               # CI/CD scripts
│   └── test-ci-workflow.sh    # CI/CD workflow tester
└── utils/            # Utility functions
    ├── index.ts               # String utilities
    └── __tests__/             # Tests for utilities
        └── string-utils.test.ts
```

## Testing

All scripts have corresponding tests in their respective `__tests__` directories. Tests are written using:

- **TypeScript/JavaScript**: Vitest for TS/JS files
- **Python**: unittest for Python files
- **Shell**: Custom test scripts for shell scripts

To run all tests:

```bash
make test-scripts
```

Or run specific test types:

```bash
cd scripts
pnpm test:ts    # Run TypeScript tests
pnpm test:py    # Run Python tests
pnpm test:sh    # Run Shell script tests
```

## Branch Management Scripts

### create-branch.ts

Interactive CLI for creating feature and fix branches following the project's branching strategy.

```bash
# Interactive mode
node scripts/branch/create-branch.ts

# Non-interactive mode
node scripts/branch/create-branch.ts --type feat --name "new-feature"
node scripts/branch/create-branch.ts --type fix --name "bug-fix" --automerge
```

### feature.sh

Shell script for creating feature branches with additional validation.

```bash
./scripts/branch/feature.sh
```

### block-main-push.py

Git pre-push hook to prevent direct pushes to protected branches (main, dev).

## Test Scripts

### test-app.ts

Unified interface for running tests in local or CI environments.

```bash
node scripts/test/test-app.ts local
node scripts/test/test-app.ts ci
```

### test-workflow.sh

Tests GitHub Actions workflows locally using act.

```bash
./scripts/test/test-workflow.sh -w workflow_file.yml -e push
```

### test-workflow-selector.ts

Interactive selector for testing GitHub workflows.

```bash
node scripts/test/test-workflow-selector.ts
```

## Development Tools

### dev-generate-client.sh

Generates TypeScript client code from OpenAPI specification.

```bash
./scripts/dev/dev-generate-client.sh
```

### setup-precommit.ts

Installs and configures pre-commit hooks for the project.

```bash
node scripts/dev/setup-precommit.ts
```

## CI/CD Scripts

### test-ci-workflow.sh

Tests the complete CI/CD workflow pipeline using GitHub Actions local runner.

```bash
./scripts/ci/test-ci-workflow.sh
```

## Utilities

### utils/index.ts

Contains string utility functions:

- `paramCase`: Converts a string to param-case (lowercase with hyphens)
