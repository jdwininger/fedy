#!/bin/bash
set -e

# Copy original install logic from Old Plugins
# Install the latest OpenJDK runtime available in the distro (meta-package)
# This will typically install the current recommended Java runtime (e.g., java-17/21 etc)
if command -v dnf >/dev/null 2>&1; then
    dnf install -y java-latest-openjdk
elif command -v yum >/dev/null 2>&1; then
    yum install -y java-latest-openjdk
else
    echo "No supported package manager found (dnf/yum). Please install OpenJDK manually." >&2
    exit 1
fi

# confirm java exists
if command -v java >/dev/null 2>&1; then
    java -version 2>&1 | sed -n '1p'
    echo "OpenJDK installed."
    exit 0
else
    echo "Java installation reported success but 'java' is not available on PATH." >&2
    exit 1
fi
