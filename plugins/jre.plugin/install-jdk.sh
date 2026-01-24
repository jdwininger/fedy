#!/bin/bash
set -e

# Install the OpenJDK development kit (JDK) - distro meta-package
if command -v dnf >/dev/null 2>&1; then
    dnf install -y java-latest-openjdk-devel
elif command -v yum >/dev/null 2>&1; then
    yum install -y java-latest-openjdk-devel
else
    echo "No supported package manager found (dnf/yum). Please install OpenJDK JDK manually." >&2
    exit 1
fi

# Confirm javac exists
if command -v javac >/dev/null 2>&1; then
    javac -version 2>&1 | sed -n '1p'
    echo "OpenJDK JDK installed."
    exit 0
else
    echo "JDK installation reported success but 'javac' is not available on PATH." >&2
    exit 1
fi
