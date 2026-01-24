#!/bin/bash
set -e

# Remove the java-latest-openjdk package (runtime only)
if command -v dnf >/dev/null 2>&1; then
    dnf remove -y java-latest-openjdk || true
elif command -v yum >/dev/null 2>&1; then
    yum remove -y java-latest-openjdk || true
else
    echo "No supported package manager found (dnf/yum). Please remove OpenJDK manually." >&2
    exit 1
fi

echo "OpenJDK removed (if present)."
