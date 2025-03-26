# GitHub Actions Workflows

## Workflow Organization

### Core Workflows
These workflows manage our branching strategy and core CI/CD processes:

- **branch-protection.yml**: Prevents direct pushes to the main branch
- **feature-branch-checks.yml**: Runs checks for feature branches
- **fix-branch.yml**: Handles fix branches with optional automerge
- **main-branch.yml**: Main branch production workflow

### Testing Workflows
These workflows ensure code quality and security:

- **lint.yml**: Code formatting and style checks
- **security.yml**: Security vulnerability scanning
- **test-workflow.yml**: Unit and integration tests
- **test-changelog.yml**: Changelog validation

### Deployment Workflows
These workflows handle deployment and container management:

- **push-to-ghcr.yml**: Container image pushes to GitHub Container Registry
- **update-docs.yml**: Documentation updates

### Disabled Workflows
The following workflows are currently disabled:

- **auto-pr.yml.disabled**: Automated PR creation
- **pr-workflow.yml.disabled**: PR handling
- **latest-changes.yml.disabled**: Change tracking

## Shared Resources

The `_shared` directory contains reusable workflow components:

- **jobs.yml.disabled**: Shared job definitions

## Workflow Dependencies

1. Core Workflows (must be enabled first):
   - branch-protection.yml
   - main-branch.yml
   - feature-branch.yml
   - fix-branch.yml

2. Support Workflows:
   - pr-workflow.yml
   - push-to-ghcr.yml
   - auto-pr.yml

3. CI/CD Workflows:
   - testing/*
   - ci/*
   - deploy/*

4. Utility Workflows:
   - latest-changes.yml

## How to Enable a Workflow

Use the `enable-workflow.sh` script in the root directory:

```bash
./enable-workflow.sh .github/workflows/workflow-name.yml.disabled
```

## Best Practices

1. Always test workflows in feature branches before enabling them
2. Follow the dependency order when enabling workflows
3. Keep shared components in the `_shared` directory
4. Document any workflow-specific requirements or configurations
5. Regularly review and update workflow dependencies

## Troubleshooting

If you encounter issues with workflows, check:

1. The workflow logs for detailed error messages
2. The workflow dependencies to ensure all required components are enabled
3. The shared resources to ensure they are properly configured
4. The workflow permissions to ensure they have the necessary access

## Version Control

All workflow files should be version controlled and follow these naming conventions:

- Active workflows: `*.yml`
- Disabled workflows: `*.yml.disabled`
- Shared components: `_shared/*`
