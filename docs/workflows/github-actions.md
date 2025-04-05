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
7. **Automerge** - Automatically merges fix branches with the `-automerge` suffix to the dev branch after tests pass

## Local Testing with Act

You can test GitHub Actions workflows locally using our consolidated testing script:
