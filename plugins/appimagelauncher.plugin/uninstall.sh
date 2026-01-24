#!/bin/bash
set -e

# Remove system RPM if present
if rpm --quiet --query appimagelauncher >/dev/null 2>&1; then
    if command -v dnf >/dev/null 2>&1; then
        dnf remove -y appimagelauncher || true
    elif command -v yum >/dev/null 2>&1; then
        yum remove -y appimagelauncher || true
    fi
fi

# Also remove any user AppImage copies and desktop entries that may exist
shopt -s nullglob
files=("$HOME/Applications/AppImageLauncher"/appimagelauncher*.AppImage "$HOME/Applications/AppImageLauncher"/*.AppImage)
for f in "${files[@]}"; do
    rm -f "$f"
done

rm -f "$HOME/.local/share/applications/appimagelauncher-lite.desktop"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/appimagelauncher.png"

echo "AppImageLauncher removed." 
exit 0