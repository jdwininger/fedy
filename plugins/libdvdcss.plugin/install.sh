#!/bin/bash

# Use RPM Fusion's tainted release to provide libdvdcss
# This follows the recommended steps:
#   sudo dnf install rpmfusion-free-release-tainted
#   sudo dnf install libdvdcss

set -euo pipefail

# Install RPM Fusion tainted release package (non-interactive)
if ! rpm -q rpmfusion-free-release-tainted >/dev/null 2>&1; then
    dnf -y install rpmfusion-free-release-tainted
fi

# Install libdvdcss
dnf -y install libdvdcss
