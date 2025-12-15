#!/usr/bin/env bash
set -euo pipefail

# uninstall.sh for visualstudiocode.plugin
if [ "$(id -u)" -ne 0 ]; then
  echo "This uninstall script must be run as root" >&2
  exit 1
fi

if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  if rpm -q code >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
      dnf -y remove code
    else
      yum -y remove code
    fi
  fi
  rm -f /etc/yum.repos.d/vscode.repo || true
  exit 0
fi

echo "No supported RPM package manager found (dnf/yum). This plugin targets Fedora." >&2
exit 2
