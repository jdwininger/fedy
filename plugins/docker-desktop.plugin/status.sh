#!/usr/bin/env bash
set -euo pipefail

# Status: return 0 if Docker Desktop package is installed
if rpm --quiet --query docker-desktop; then
  exit 0
fi

exit 1
