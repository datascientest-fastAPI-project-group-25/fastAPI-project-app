#!/bin/bash
set -e

# Start PostgreSQL service
service postgresql start

# Keep container running for act
exec "$@"
