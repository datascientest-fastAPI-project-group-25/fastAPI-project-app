# Scripts Cleanup

This document lists scripts that appear to be one-offs and can potentially be removed from the codebase. These scripts are not attached to any critical workflows or are duplicated elsewhere.

## One-off Scripts Removed

### Root Directory
- `organize-scripts.sh` - One-time script used to organize files in the scripts directory
- `run-script-tests.sh` - Simple wrapper for running tests that's redundant with the Makefile targets

### Setup Scripts
- `scripts/setup/init_db.py` - Database initialization script that appears to be a one-time setup
- `scripts/setup/setup_project.sh` - Project setup script that duplicates functionality in `scripts/dev/setup-project.sh`
- `backend/scripts/init_db.py` - Backend database initialization script that doesn't appear to be referenced

### Test Scripts
- `scripts/test/diagnose-act.sh` - Diagnostic script for GitHub Actions local runner
- `scripts/test/test-docs-update.sh` - Test script for documentation updates

## Scripts Referenced in Makefile (Not Removed)

- `scripts/ci/test-ci-workflow.sh` - Referenced in Makefile target `test-ci-workflow`

## Note

If you need any of these scripts in the future, you can restore them from version control history.

Before removing any additional scripts, please verify they are not referenced in:
1. GitHub Actions workflows (active or disabled)
2. Makefile targets
3. package.json scripts
4. Other shell scripts or automation
