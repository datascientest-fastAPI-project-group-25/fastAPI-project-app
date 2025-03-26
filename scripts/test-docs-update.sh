#!/bin/bash

# Simulate fetching changelog from API
changelog="# Changelog
## Test Update

* Initial commit by Test User on 2025-03-25
* Add test feature by Test User on 2025-03-25"

# Simulate updating documentation file
echo "$changelog" > docs/CHANGELOG.md

echo "Simulated documentation update complete!"
echo "Changelog written to docs/CHANGELOG.md"
