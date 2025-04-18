# TODO List

## Missing Features

### Makefile Modularization

- [ ] make dev and other useful commands
- [ ] Create a proper modular Makefile system with clear separation of concerns
- [ ] Move targets to appropriate module files:
  - [ ] variables.mk (common variables and settings)
  - [ ] environment.mk (environment setup and configuration)
  - [ ] docker.mk (Docker-related targets)
  - [ ] testing.mk (testing and validation targets)
  - [ ] maintenance.mk (cleanup and maintenance targets)
  - [ ] development.mk (development workflow targets)
  - [ ] ci.mk (CI/CD related targets)
  - [ ] workflows.mk (GitHub workflow testing targets)
- [ ] Add test-workflow target for testing GitHub workflows locally with appropriate environment variables
- [ ] Ensure proper dependency management between modules
- [ ] Add documentation for each module
- [ ] Add validation to ensure all required variables are set
- [ ] Add error handling and logging
- [ ] Add progress indicators for long-running tasks
- [ ] Add dry-run capability for destructive operations
- [ ] Add help text for each module
- [ ] Add version information
- [ ] Add module-specific configuration options

### Testing

- [ ] Implement accessibility testing (a11y-audit, a11y-lighthouse, a11y-wcag, a11y-report)
- [ ] Add Lighthouse performance testing
- [ ] Add WCAG compliance checks
- [ ] Set up accessibility reporting
- [x] Add unit test separation (backend/frontend)
- [ ] Add integration test separation (backend/frontend)
- [x] Add end-to-end test suite
- [ ] Add test coverage reporting
- [ ] Add test report generation

### Documentation

- [ ] Add detailed documentation for each Makefile section
- [ ] Create architecture documentation
- [ ] Add API documentation
- [ ] Add frontend documentation
- [ ] Add backend documentation

### CI/CD

- [x] Set up GitHub Actions workflows
- [x] Add automated testing in CI
- [ ] Add automated deployment
- [ ] Add automated documentation generation
- [ ] Improve local workflow testing with Docker-compatible alternatives
- [ ] Create environment-specific workflow configurations for dev, staging, and production

### Security

- [ ] Implement security scanning
- [ ] Add dependency vulnerability checks
- [ ] Add code security analysis
- [ ] Add container security scanning

### Monitoring

- [ ] Set up Prometheus metrics
- [ ] Configure Grafana dashboards
- [ ] Add logging infrastructure
- [ ] Add alerting system

### Docker Management

- [x] Add container build targets (docker-build, docker-build-frontend, docker-build-backend)
- [ ] Add container registry management (docker-push, docker-pull)
- [x] Add container monitoring (docker-logs, docker-stats)
- [x] Add container maintenance (docker-prune)
- [x] Add container shell access (docker-shell)

## Improvements

### Development Experience

- [ ] Add development environment setup script
- [ ] Improve error messages in Makefile targets
- [ ] Add progress indicators for long-running tasks
- [ ] Add validation for environment variables

### Code Quality

- [ ] Add more comprehensive linting rules
- [ ] Add code coverage requirements
- [ ] Add performance benchmarks
- [ ] Add code complexity checks

### Docker

- [ ] Optimize Docker builds
- [ ] Add multi-stage builds for all services
- [ ] Add Docker Compose profiles
- [ ] Add Docker health checks

### Maintenance

- [x] Add Docker cleanup targets (clean-docker)
- [x] Add Node.js cleanup targets (clean-node)
- [x] Add Python cleanup targets (clean-python)
- [x] Add dependency update targets (update, update-backend, update-frontend)
- [x] Add development tools update target (update-tools)

## Workflow Optimization Plan

1. **Streamline Python tools**
   - [x] Remove redundant tools (black, mypy)
   - [x] Focus on uv for dependency management
   - [x] Use ruff for linting and formatting

2. **Frontend improvements**
   - [x] Use Biome for formatting and linting
   - [x] Maintain pnpm for package management

3. **Security checks**
   - [x] Keep bandit and pip-audit
   - [x] Add safety checks for Python dependencies
   - [x] Run npm audit for frontend

4. **Testing strategy**
   - [x] Maintain pytest for backend tests
   - [x] Keep frontend test framework
   - [ ] Add coverage reporting

5. **Workflow optimization**
   - [x] Reduce duplicate setup steps
   - [x] Enable caching for uv and pnpm
   - [x] Set appropriate timeouts

## Branching Strategy Implementation Plan (2025-03-25)

1. **Main Branch Protection**
   - [ ] Add workflow to block direct pushes to main
   - [ ] Configure MachineUser for main branch testing
   - [ ] Set up required reviews for PRs to main

2. **Dev Branch Setup**
   - [ ] Create dev branch if not exists
   - [ ] Add workflow for staging deployments
   - [ ] Configure PR requirements for dev branch

3. **Branch Creation Process**
   - [ ] Enhance create-branch CLI tool
   - [ ] Add pre-branch creation checks (fetch main)
   - [ ] Implement branch type validation (feat/fix)

4. **Automated PR Workflow**
    - [ ] Fix/Complete auto-PR creation for feat/fix branches
    - [ ] Configure required checks for PRs
    - [ ] Set up automatic staging builds on PR merge
    - [x] Implement automerge functionality for fix/*-automerge branches

5. **Main Branch Integration**
   - [ ] Add auto-PR creation from dev to main
   - [ ] Configure production builds on main merge
   - [ ] Implement version tagging and changelog generation

6. **Testing & Validation**
   - [ ] Test MachineUser access with GH Action Secrets
   - [ ] Verify staging deployment workflow
   - [ ] Validate production build process

## Workflow Testing Results (2025-03-26)

### Next Steps for Workflow Testing
- [ ] Create a Makefile target for testing workflows with appropriate environment variables
- [ ] Create simplified versions of workflows for local testing that don't rely on Docker services
- [ ] Add documentation on how to test workflows locally
- [ ] Fix local act setup to handle newer GitHub Actions features and Docker-in-Docker requirements

### Feature Branch Workflow
- [ ] feature/feature-push.yml
  - Issue: Database connection fails due to missing PostgreSQL service
  - Status: ❌ Failing
  - Notes: Added PostgreSQL service configuration and environment variables
  - Fix: Added PostgreSQL service with health checks, environment variables, and wait script
  - Additional Issue: Still failing in local testing with act due to Docker-in-Docker limitations

### Development Workflows
- [ ] dev/merge-to-dev.yml
  - Issue: Docker Buildx integration causing issues with act local testing
  - Status: ❌ Failing
  - Notes: Added Docker Buildx setup and health check
  - Fix: Updated workflow with proper Docker setup and health check
- [ ] dev/pr-to-dev.yml
  - Issue: Incorrect Docker build command and missing step for image push
  - Status: ❌ Failing
  - Notes: Fixed Docker build command and separated login and push steps
  - Fix: Updated workflow with correct Docker build command and proper step separation

### Main Branch Workflows
- [ ] main/merge-to-main.yml
  - Issue: Incorrect Docker build command and missing step for image push
  - Status: ❌ Failing
  - Notes: Fixed Docker build command and separated login and push steps
  - Fix: Added Docker Buildx setup, fixed build command, separated login and push steps, added health check
- [ ] main/pr-to-main.yml
  - Issue: Using pip instead of uv and missing PostgreSQL service
  - Status: ❌ Failing
  - Notes: Updated to use uv for dependency management and added PostgreSQL service
  - Fix: Added PostgreSQL service with health checks, environment variables, and wait script

### Pre-commit Workflow
- [ ] pre-commit/pre-commit.yml
  - Issue: Docker integration causing issues with act local testing
  - Status: ❌ Failing
  - Notes: Updated to use simplified approach with environment variables and skipping Docker-dependent hooks
  - Fix: Removed uv dependency and Docker requirements, added environment variables for testing

### Shared Workflows
- [ ] shared/shared-build.yml
  - Issue: Incorrect Docker build command and missing step for image push
  - Status: ❌ Failing
  - Notes: Fixed Docker build command and separated login and push steps
  - Fix: Added Docker Buildx setup, fixed build command, separated login and push steps
- [ ] shared/shared-release.yml
  - Status: ✅ Looks Good
  - Notes: No issues identified, workflow structure is correct
- [ ] shared/shared-tests.yml
  - Issue: Using pip instead of uv and missing PostgreSQL service
  - Status: ❌ Failing
  - Notes: Updated to use uv for dependency management and added PostgreSQL service
  - Fix: Added PostgreSQL service with health checks, environment variables, and wait script

## Notes

- These features should be implemented incrementally
- Each feature should be properly tested before being added
- Documentation should be updated as features are added
- Consider adding feature flags for experimental features
- Makefile modularization should be done carefully to avoid breaking existing functionality
- Each module should be self-contained and have clear dependencies
- Consider using a module loader pattern for better organization
- Add version compatibility checks between modules
