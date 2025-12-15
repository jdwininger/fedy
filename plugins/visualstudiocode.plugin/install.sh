#!/usr/bin/env bash
set -euo pipefail

# install.sh for visualstudiocode.plugin
# Supports RPM (dnf) and Debian (apt) based systems.

GPG_URL="https://packages.microsoft.com/keys/microsoft.asc"

if [ "$(id -u)" -ne 0 ]; then
  echo "This install script must be run as root" >&2
  exit 1
fi

enabled=1
gpgcheck=1
gpgkey=$GPG_URL
if command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
  # RPM-based only (Fedora-targeted)
  echo "Installing Visual Studio Code (RPM)"
  rpm --import "$GPG_URL" || true
  cat > /etc/yum.repos.d/vscode.repo <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=$GPG_URL
EOF
  if command -v dnf >/dev/null 2>&1; then
    dnf -y install code
  else
    yum -y install code
  fi
  exit $?
fi

echo "No supported RPM package manager found (dnf/yum). This plugin targets Fedora." >&2
exit 2
