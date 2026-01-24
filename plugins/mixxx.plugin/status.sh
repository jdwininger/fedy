#!/usr/bin/env bash
set -euo pipefail

# Status: return 0 if mixxx package is installed
if rpm --quiet --query mixxx; then
  exit 0
fi

exit 1
