# GitHub Actions Workflows

This document provides an overview of the GitHub Actions workflows used in this project, including best practices for local testing and troubleshooting.

## Workflow Overview

The project uses several GitHub Actions workflows to automate testing, building, and deployment:

1. **Test Docker Compose** - Tests the Docker Compose setup
2. **Generate API Client** - Automatically generates the frontend API client
3. **Format and Lint** - Runs code formatting and linting checks
4. **Feature Branch Checks** - Runs tests on feature branches
5. **Deploy to Staging** - Deploys to the staging environment
6. **Deploy to Production** - Deploys to the production environment

## Local Testing with Act

You can test GitHub Actions workflows locally using [act](https://github.com/nektos/act), which runs your GitHub Actions locally using Docker.

### Setup

1. Install act:
   ```bash
   brew install act
   ```

2. Use the provided script to test workflows:
   ```bash
   ./scripts/test-workflow.sh [workflow-file] [event-type]
   ```

   Example:
   ```bash
   ./scripts/test-workflow.sh feature-branch-checks.yml push
   ```

### Configuration

The project includes an `.actrc` file with the following configurations:

```
-P ubuntu-latest=node:18-bullseye
--env-file=.env
-s GITHUB_TOKEN=
--bind
```

This configuration:
- Uses Node.js-based Docker images required for workflows using Node.js
- Sets CI=true to avoid warnings
- Configures secrets as needed

### Common Issues

When testing GitHub Actions workflows locally:

1. **Docker Image Configuration**:
   - Node-based images (node:18-bullseye, node:16-bullseye) are required for workflows using Node.js
   - These images have Node.js pre-installed, solving the "node: executable file not found" error

2. **Security Scan Failures**:
   - Bandit may detect low severity issues in test code
   - Use the `--skip-security` flag to skip security checks during local testing

3. **Missing Frontend Test Script**:
   - pnpm error "Missing script: test" may occur
   - This is expected if you haven't defined a test script in package.json

4. **Vulnerabilities in Frontend Dependencies**:
   - pnpm audit may report vulnerabilities
   - Use `--skip-audit` to bypass this check during local testing

## Workflow Improvements

Recent improvements to workflows include:

1. **Error Handling**:
   - Added checks for tool availability (Docker, `uv`)
   - Implemented conditional steps based on tool availability
   - Enhanced logging for better debugging

2. **Cleanup Steps**:
   - Made cleanup steps always run, even if previous steps fail
   - Added proper error handling for git operations

3. **Performance Improvements**:
   - Added pnpm caching for frontend
   - Enabled uv caching for Python dependencies
   - Improved working directory usage

## Best Practices

When modifying workflows:

1. Always test locally with act before pushing changes
2. Add proper error handling and conditional checks
3. Use `if: always()` for cleanup steps
4. Add verbose logging for easier debugging
5. Make non-critical checks (like style checks) non-blocking
6. Use standardized configurations across workflows
