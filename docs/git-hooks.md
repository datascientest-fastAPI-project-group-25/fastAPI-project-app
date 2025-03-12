# Git Hooks with pre-commit

This project uses [pre-commit](https://pre-commit.com/) to manage Git hooks for code quality enforcement.

## What is pre-commit?

pre-commit is a framework for managing and maintaining multi-language pre-commit hooks. It helps maintain code quality by running checks before commits and pushes, ensuring consistent code quality across the project.

## Features

Our pre-commit configuration provides:

- **Pre-commit hooks**:
  - Code formatting with Black
  - Linting and auto-fixing with Ruff
  - Security scanning with Bandit
  - Trailing whitespace removal
  - YAML validation
  - Merge conflict detection

- **Pre-push hooks**:
  - Running tests with pytest

- **Commit message validation**:
  - Enforcing conventional commit format

## Setup

To set up pre-commit in your development environment:

```bash
# Make the setup script executable
chmod +x scripts/setup-precommit.sh

# Run the setup script
./scripts/setup-precommit.sh

# Or install directly
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
```

## Manual Usage

You can manually run the hooks:

```bash
# Run all pre-commit hooks
pre-commit run --all-files

# Run all pre-push hooks
pre-commit run --hook-stage pre-push --all-files

# Run a specific hook
pre-commit run black --all-files
```

## Configuration

The pre-commit configuration is stored in `.pre-commit-config.yaml` at the root of the project. You can modify this file to add, remove, or customize hooks.

## Skipping Hooks

In rare cases when you need to bypass the hooks:

```bash
# Skip all hooks for a commit
git commit --no-verify -m "Your message"

# Skip specific hooks
SKIP=black,ruff git commit -m "Your message"
```

**Note**: Skipping hooks should be done only in exceptional circumstances, as it bypasses important code quality checks.
