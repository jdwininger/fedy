#!/bin/bash
# Return 0 if AppImageLauncher appears to be installed, non-zero otherwise.

# Check RPM packages
if rpm -qa | grep -i appimagelauncher >/dev/null 2>&1; then
    exit 0
fi

# Check for common binaries
if command -v appimagelauncher >/dev/null 2>&1; then
    exit 0
fi
if [ -x /usr/bin/appimagelauncher ] || [ -x /usr/local/bin/appimagelauncher ]; then
    exit 0
fi

# Check for desktop file (installers sometimes place a .desktop in /usr/share/applications)
if ls /usr/share/applications/*appimagelauncher*.desktop >/dev/null 2>&1; then
    exit 0
fi

# Not found
exit 1
