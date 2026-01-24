#!/usr/bin/env bash
set -euo pipefail

if command -v wine >/dev/null 2>&1 && command -v winetricks >/dev/null 2>&1; then
  exit 0
fi

exit 1
