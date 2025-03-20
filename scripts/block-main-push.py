#!/usr/bin/env python3
import subprocess  # nosec
import sys

try:
    branch = (
        subprocess.check_output("/usr/bin/git symbolic-ref --short HEAD", shell=True)
        .decode()
        .strip()
    )
    if branch == "main":
        print("❌ ERROR: Direct pushes to main branch are not allowed.")
        print(
            "Please create a feature (feat/*) or fix branch and submit a pull request instead."
        )
        print("Run: ./scripts/create-branch.sh to create a proper branch.")
        sys.exit(1)
except Exception as e:
    print(f"Error checking branch: {e}")
    sys.exit(1)

sys.exit(0)
