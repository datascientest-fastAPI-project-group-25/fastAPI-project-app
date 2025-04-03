#!/usr/bin/env python3
import os
import re
import sys
from enum import Enum

VERSION_FILE = "VERSION"


class VersionType(Enum):
    MAJOR = "major"
    MINOR = "minor"
    PATCH = "patch"


def read_version():
    """Read the current version from the VERSION file."""
    if not os.path.exists(VERSION_FILE):
        with open(VERSION_FILE, "w") as f:
            f.write("0.1.0")
        return "0.1.0"

    with open(VERSION_FILE, "r") as f:
        version = f.read().strip()

    # Validate version format
    if not re.match(r"^\d+\.\d+\.\d+$", version):
        print(f"Error: Invalid version format in {VERSION_FILE}. Expected format: X.Y.Z")
        sys.exit(1)

    return version


def write_version(version):
    """Write the new version to the VERSION file."""
    with open(VERSION_FILE, "w") as f:
        f.write(version)


def bump_version(version_type):
    """Bump the version according to the specified type."""
    current_version = read_version()
    major, minor, patch = map(int, current_version.split("."))

    if version_type == VersionType.MAJOR:
        major += 1
        minor = 0
        patch = 0
    elif version_type == VersionType.MINOR:
        minor += 1
        patch = 0
    elif version_type == VersionType.PATCH:
        patch += 1

    new_version = f"{major}.{minor}.{patch}"
    write_version(new_version)
    return new_version


def main():
    """Main function to handle command line arguments."""
    if len(sys.argv) < 2:
        print("Usage: python version.py [get|bump <major|minor|patch>]")
        sys.exit(1)

    command = sys.argv[1]

    if command == "get":
        print(read_version())
    elif command == "bump":
        if len(sys.argv) < 3:
            print("Error: Missing version type. Expected: major, minor, or patch")
            sys.exit(1)

        version_type_str = sys.argv[2].lower()
        try:
            version_type = VersionType(version_type_str)
        except ValueError:
            print(f"Error: Invalid version type '{version_type_str}'. Expected: major, minor, or patch")
            sys.exit(1)

        new_version = bump_version(version_type)
        print(f"Version bumped to {new_version}")
    else:
        print(f"Error: Unknown command '{command}'. Expected: get or bump")
        sys.exit(1)


if __name__ == "__main__":
    main()
