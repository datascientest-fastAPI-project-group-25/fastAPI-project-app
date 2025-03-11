# DevOps Demo Application

This repository contains a FastAPI backend and React frontend application with a comprehensive CI/CD pipeline for AWS deployment.

## Development Workflow

### Branch Strategy

1. **Feature Branches (`feat/*`)**
   - Create for new features or bug fixes
   - Must pass pre-commit hooks before pushing
   - On push triggers:
     * Style checks (black, flake8, eslint, prettier)
     * Security checks (bandit, npm audit, pip-audit)
     * Linting & formatting
     * Unit tests
   - Requires PR review to merge to `dev`

2. **Development Branch (`dev`)**
   - Integration branch for feature development
   - On push triggers:
     * Minimal test suite (unit, linting, security)
     * Automatic staging deployment
   - PR to `main` triggers:
     * Full test suite (integration, e2e, API)
     * Security scans
     * Performance tests
     * Documentation updates
     * Changelog generation

3. **Main Branch (`main`)**
   - Production-ready code
   - Protected branch requiring PR approval
   - On push/PR merge:
     * Complete test suite
     * Security scans
     * Dependency checks
   - Release tags trigger production deployment

### Pre-commit Requirements

All commits must pass the following checks:
- Style checks:
  * Backend: black, flake8
  * Frontend: eslint, prettier
- Security checks:
  * Backend: bandit, pip-audit
  * Frontend: npm audit
- Linting & formatting
  * Enforced by pre-commit hooks
  * Must pass before commit is allowed

### Getting Started

1. Install pre-commit hooks:
```bash
pip install pre-commit
pre-commit install
```

2. Install dependencies:
```bash
# Backend
cd backend
python -m venv .venv
source .venv/bin/activate
pip install uv
uv sync

# Frontend
cd ../frontend
npm install
```

3. Start development environment:
```bash
docker compose up -d
```

### Development Guidelines

1. **Creating a Feature**
   ```bash
   git checkout dev
   git pull
   git checkout -b feat/your-feature-name
   # Make changes
   git commit -m "feat: your feature description"
   # Create PR to dev branch
   ```

2. **Updating Documentation**
   - Update relevant README files
   - Add/update API documentation
   - Update changelog if necessary

3. **Code Review Process**
   - All PRs require at least one review
   - Must pass all CI checks
   - Follow the PR template guidelines

4. **Release Process**
   1. Merge `dev` to `main` via PR
   2. Create a release tag
   3. Automated deployment to production

## Docker Compose

Start the local development environment:
```bash
docker compose up -d
```

Services:
- Backend: http://localhost:8000
- Frontend: http://localhost:5173
- API Docs: http://localhost:8000/docs
- Adminer: http://localhost:8080

## CI/CD Pipeline

Our CI/CD pipeline uses GitHub Actions for automation and AWS for deployment:

1. **Continuous Integration**
   - Automated testing
   - Code quality checks
   - Security scanning
   - Performance testing

2. **Continuous Deployment**
   - Staging environment (dev branch)
   - Production environment (main branch releases)
   - AWS ECS deployment
   - Docker image management in ECR

## Environment Setup and Configuration

### Environment Variables

The application uses environment variables for configuration. A sample `.env.example` file is provided as a template.

1. **Creating Your Environment File**:
   ```bash
   cp .env.example .env
   ```

2. **Important Environment Variables**:
   - `DOMAIN`: Sets the base domain for the application
   - `SECRET_KEY`: Used for JWT token generation and security
   - `BACKEND_CORS_ORIGINS`: Configures CORS for the API
   - `POSTGRES_*`: Database connection settings
   - `FIRST_SUPERUSER_*`: Initial admin user credentials

3. **Security Best Practices**:
   - Never commit `.env` files to version control
   - Use strong, unique passwords for all credentials
   - Rotate secrets regularly in production environments
   - Use different credentials for development, staging, and production

### Subdomain-Based Routing

The application uses a subdomain-based routing approach for different services:

1. **Local Development**:
   - API: http://api.localhost
   - Frontend: http://dashboard.localhost
   - API Docs: http://api.localhost/docs
   - Adminer: http://db.localhost

2. **Configuration**:
   - The routing is handled by nginx in production
   - Local development can use the same pattern with appropriate hosts file entries
   - CORS is configured to allow cross-subdomain communication

3. **Adding a Host Entry (Local Development)**:
   ```bash
   # Add to /etc/hosts
   127.0.0.1 api.localhost dashboard.localhost db.localhost
   ```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feat/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feat/amazing-feature`)
5. Open a Pull Request to the `dev` branch
