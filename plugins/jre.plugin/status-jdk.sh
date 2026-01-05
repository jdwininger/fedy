#!/bin/bash
# Return 0 if a JDK (javac) is installed, non-zero otherwise

# Check for javac binary
if command -v javac >/dev/null 2>&1; then
    exit 0
fi

# Check rpm packages for OpenJDK-devel
if rpm -qa | grep -i openjdk | grep -i devel >/dev/null 2>&1; then
    exit 0
fi

exit 1
