#!/bin/bash
set -e

# Copy original install logic from Old Plugins
if [ -f "$(pwd)/../Old Plugins/jre.plugin/install.sh" ]; then
    run-as-root -s "$(pwd)/../Old Plugins/jre.plugin/install.sh"
else
    echo "Original JRE install script not found; please implement manual installation steps."
    exit 1
fi
