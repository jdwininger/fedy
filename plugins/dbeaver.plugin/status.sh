#!/usr/bin/env bash
set -euo pipefail

# Status: return 0 if dbeaver-ce package is installed
if rpm --quiet --query dbeaver-ce; then
  exit 0
fi

exit 1
