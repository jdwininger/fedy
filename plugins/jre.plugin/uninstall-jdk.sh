#!/bin/bash
set -e

# Remove the OpenJDK development package
if command -v dnf >/dev/null 2>&1; then
    dnf remove -y java-latest-openjdk-devel || true
elif command -v yum >/dev/null 2>&1; then
    yum remove -y java-latest-openjdk-devel || true
else
    echo "No supported package manager found (dnf/yum). Please remove OpenJDK JDK manually." >&2
    exit 1
fi

echo "OpenJDK JDK removed (if present)."
