#!/bin/bash
set -e

# Install AppImageLauncher system RPM (user provided suggested RPM URL)
RPM_URL="https://github.com/TheAssassin/AppImageLauncher/releases/download/v3.0.0-beta-3/appimagelauncher_3.0.0-beta-2-gha287.96cb937_x86_64.rpm"
TMPDIR=$(mktemp -d)
RPMFILE="$TMPDIR/$(basename "$RPM_URL")"

echo "Downloading AppImageLauncher RPM..."
wget --content-disposition -O "$RPMFILE" "$RPM_URL"

# Install RPM
echo "Installing AppImageLauncher (requires root)..."
if command -v dnf >/dev/null 2>&1; then
    dnf install -y "$RPMFILE"
elif command -v yum >/dev/null 2>&1; then
    yum install -y "$RPMFILE"
else
    echo "No package manager found (dnf/yum). Please install the RPM manually: $RPMFILE" >&2
    exit 1
fi

rm -rf "$TMPDIR"

echo "AppImageLauncher installed."

exit 0
