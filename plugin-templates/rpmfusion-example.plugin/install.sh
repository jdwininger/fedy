#!/usr/bin/env bash
set -euo pipefail

# Example plugin install script for packages provided by RPM Fusion
# This script MUST run as root (Fedy metadata will call it via `run-as-root -s`)

APP="example-package"                   # package name to install (replace)
# Control whether this package requires RPM Fusion nonfree repo to be present.
# Set NEED_NONFREE=true when your package requires the nonfree repository (default: false)
NEED_NONFREE="${NEED_NONFREE:-false}"

# Which rpm fusion release packages to check
FREE_REPO_PKG="rpmfusion-free-release"
NONFREE_REPO_PKG="rpmfusion-nonfree-release"

# dnf is expected to be present on target systems - no pre-check needed

# Check whether required rpmfusion repo(s) are installed. We do NOT add repos here.
if [ "$NEED_NONFREE" = "true" ]; then
  # Package requires nonfree repo
  if ! rpm -q "$NONFREE_REPO_PKG" >/dev/null 2>&1; then
    echo "RPM Fusion (nonfree) does not appear to be enabled. Aborting install." >&2
    # Exit code 4 indicates required nonfree repo missing
    exit 4
  fi
else
  # If not explicitly requiring nonfree, accept either free or nonfree being present
  if ! rpm -q "$FREE_REPO_PKG" >/dev/null 2>&1 && ! rpm -q "$NONFREE_REPO_PKG" >/dev/null 2>&1; then
    echo "RPM Fusion (free or nonfree) does not appear to be enabled. Aborting install." >&2
    # Exit code 3 indicates repo missing
    exit 3
  fi
fi

echo "RPM Fusion detected; installing ${APP} via dnf..."
dnf -y install "$APP"
exit $?
