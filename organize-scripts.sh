#!/bin/bash

# Script to organize remaining files in the scripts directory

echo "Organizing remaining files in the scripts directory..."

# Create docs directory if it doesn't exist
mkdir -p scripts/docs

# Move testing-related files to scripts/test/
echo "Moving testing-related files to scripts/test/"
[ -f "scripts/test-local.sh" ] && mv scripts/test-local.sh scripts/test/test-local.sh
[ -f "scripts/run-tests.sh" ] && mv scripts/run-tests.sh scripts/test/run-tests.sh
[ -f "scripts/diagnose-act.sh" ] && mv scripts/diagnose-act.sh scripts/test/diagnose-act.sh

# Move CI/CD-related files to scripts/ci/
echo "Moving CI/CD-related files to scripts/ci/"
[ -f "scripts/deploy-app.sh" ] && mv scripts/deploy-app.sh scripts/ci/deploy-app.sh

# Move development setup files to scripts/dev/
echo "Moving development setup files to scripts/dev/"
[ -f "scripts/setup_project.sh" ] && mv scripts/setup_project.sh scripts/dev/setup-project.sh

# Move documentation-related files to scripts/docs/
echo "Moving documentation-related files to scripts/docs/"
[ -f "scripts/test-docs-update.sh" ] && mv scripts/test-docs-update.sh scripts/docs/update-docs.sh

echo "Organization complete!"
