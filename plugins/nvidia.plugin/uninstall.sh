#!/usr/bin/env bash
set -euo pipefail

APP="akmod-nvidia"

# dnf is expected to be present on target systems - no pre-check needed

# Fail fast if not executed as root - the metadata should run this with run-as-root
if [ "$(id -u)" -ne 0 ]; then
  echo "This uninstall script must be run as root" >&2
  exit 1
fi

if ! rpm -q "$APP" >/dev/null 2>&1; then
  echo "$APP not installed"
  exit 0
fi

echo "Removing ${APP}..."
dnf -y remove "$APP"
exit $?
