#!/bin/bash
set -e

# This script should implement the distro-specific flow to install MS core fonts
# For now, call the original script if available in Old Plugins
if [ -f "$(pwd)/../Old Plugins/msttcorefonts.plugin/install.sh" ]; then
    run-as-root -s "$(pwd)/../Old Plugins/msttcorefonts.plugin/install.sh"
else
    echo "Please implement installation of msttcore-fonts-installer for this distro."
    exit 1
fi
