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

# Attempt to run the installed app to finalize integration. This may not
# show a GUI if a graphical session is not available for the target user,
# but running the binary is usually enough to complete registration.
if command -v appimagelauncher >/dev/null 2>&1; then
    if [ -n "$SUDO_USER" ]; then
        echo "Launching AppImageLauncher as user '$SUDO_USER' to finalize integration..."
        # Try runuser first (runs command as a different user); fall back to sudo if needed
        if command -v runuser >/dev/null 2>&1; then
            runuser -l "$SUDO_USER" -c "nohup setsid appimagelauncher >/dev/null 2>&1 &" || true
        else
            sudo -u "$SUDO_USER" bash -c "nohup setsid appimagelauncher >/dev/null 2>&1 &" || true
        fi
    else
        echo "Launching AppImageLauncher to finalize integration..."
        nohup setsid appimagelauncher >/dev/null 2>&1 & || true
    fi
else
    if [ -n "$SUDO_USER" ]; then
        echo "AppImageLauncher installed. Please ask the user '$SUDO_USER' to run 'appimagelauncher' once to finish integration."
    else
        echo "AppImageLauncher installed. Please run 'appimagelauncher' once to finish integration."
    fi
fi

exit 0
