#!/bin/bash
# Return 0 if some OpenJDK runtime is installed, non-zero otherwise

# Check for java binary
if command -v java >/dev/null 2>&1; then
    exit 0
fi

# Check RPM packages for OpenJDK
if rpm -qa | grep -i openjdk >/dev/null 2>&1; then
    exit 0
fi

exit 1
