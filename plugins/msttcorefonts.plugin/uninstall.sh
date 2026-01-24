#!/usr/bin/env bash
set -euo pipefail

# Try to use the Old Plugins uninstall if present
if [ -f "$(pwd)/../Old Plugins/msttcorefonts.plugin/uninstall.sh" ]; then
    run-as-root -s "$(pwd)/../Old Plugins/msttcorefonts.plugin/uninstall.sh"
    exit 0
fi

# Fallback: attempt to remove the package (may differ by distro)
if rpm --quiet --query msttcore-fonts-installer; then
    run-as-root dnf -y remove msttcore-fonts-installer
    exit 0
fi

echo "No uninstall action implemented for msttcorefonts on this distro." >&2
exit 1
