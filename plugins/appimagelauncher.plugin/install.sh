#!/bin/bash
set -e

# Install AppImageLauncher system RPM (user provided suggested RPM URL)
RPM_URL="https://github.com/TheAssassin/AppImageLauncher/releases/download/v3.0.0-beta-3/appimagelauncher_3.0.0-beta-2-gha287.96cb937_x86_64.rpm"
TMPDIR=$(mktemp -d)
RPMFILE="$TMPDIR/$(basename "$RPM_URL")"

# Try to install directly from the upstream URL (DNF/YUM can handle URLs).
echo "Installing AppImageLauncher (requires root)..."
if command -v dnf >/dev/null 2>&1; then
    if dnf install -y "$RPM_URL"; then
        echo "Installed AppImageLauncher from URL via dnf."
    else
        echo "dnf failed to install from URL — downloading RPM and retrying..."
        wget --content-disposition -O "$RPMFILE" "$RPM_URL" || { echo "Download failed: $RPM_URL" >&2; rm -rf "$TMPDIR"; exit 1; }
        if [ ! -s "$RPMFILE" ]; then echo "Downloaded RPM is missing or empty: $RPMFILE" >&2; rm -rf "$TMPDIR"; exit 1; fi
        echo "Downloaded: $(ls -l "$RPMFILE")"
        dnf install -y "$RPMFILE" || { echo "dnf failed to install $RPMFILE" >&2; rm -rf "$TMPDIR"; exit 1; }
    fi
elif command -v yum >/dev/null 2>&1; then
    if yum install -y "$RPM_URL"; then
        echo "Installed AppImageLauncher from URL via yum."
    else
        echo "yum failed to install from URL — downloading RPM and retrying..."
        wget --content-disposition -O "$RPMFILE" "$RPM_URL" || { echo "Download failed: $RPM_URL" >&2; rm -rf "$TMPDIR"; exit 1; }
        if [ ! -s "$RPMFILE" ]; then echo "Downloaded RPM is missing or empty: $RPMFILE" >&2; rm -rf "$TMPDIR"; exit 1; fi
        echo "Downloaded: $(ls -l "$RPMFILE")"
        yum install -y "$RPMFILE" || { echo "yum failed to install $RPMFILE" >&2; rm -rf "$TMPDIR"; exit 1; }
    fi
else
    echo "No package manager found (dnf/yum). Please install the RPM manually: $RPMFILE" >&2
    rm -rf "$TMPDIR"
    exit 1
fi

rm -rf "$TMPDIR"

echo "AppImageLauncher installed."

exit 0
