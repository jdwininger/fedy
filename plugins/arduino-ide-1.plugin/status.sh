#!/usr/bin/env bash
set -euo pipefail

# Status: return 0 if Arduino (legacy) package is installed
if rpm --quiet --query arduino; then
  exit 0
fi

exit 1
