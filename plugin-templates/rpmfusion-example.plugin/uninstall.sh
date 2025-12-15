#!/usr/bin/env bash
set -euo pipefail

APP="example-package"

# dnf is expected to be present on target systems - no pre-check needed

if ! rpm -q "$APP" >/dev/null 2>&1; then
  echo "$APP not installed"
  exit 0
fi

echo "Removing ${APP}..."
dnf -y remove "$APP"
exit $?
