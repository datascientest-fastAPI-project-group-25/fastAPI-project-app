#!/usr/bin/env python3
import subprocess  # nosec
import sys

try:
    branch = (
        subprocess.check_output(
            "/usr/bin/git symbolic-ref --short HEAD", shell=True
        ).decode().strip()
    )
    if branch == "main" or branch == "dev":
        print(f"❌ ERROR: Direct pushes to {branch} branch are not allowed.")
        print(
            "Please create a feature (feat/*) or fix branch and submit a "
            "pull request to dev instead."
        )
        print(
            "Use the following make command to create a proper branch:"
        )
        print("    make branch-create")
        print(
            "See README.md#-branching-strategy for details on our "
            "branching strategy."
        )
        sys.exit(1)
except Exception as e:
    print(f"Error checking branch: {e}")
    sys.exit(1)

sys.exit(0)
