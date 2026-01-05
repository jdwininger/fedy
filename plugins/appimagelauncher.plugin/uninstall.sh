#!/bin/bash
set -e

# First try to remove integration via a system binary, if available
if command -v appimagelauncher-lite >/dev/null 2>&1; then
    echo "Removing AppImageLauncher integration via installed binary..."
    appimagelauncher-lite remove || true
fi

# Next try to run any existing AppImage with 'remove'
shopt -s nullglob
files=("$HOME/Applications/AppImageLauncher"/appimagelauncher-lite*.AppImage "$HOME/Applications/AppImageLauncher"/*.AppImage)
for f in "${files[@]}"; do
    echo "Running $f remove..."
    "$f" remove || true
    rm -f "$f"
done

# Remove desktop entry and icons created by installer
rm -f "$HOME/.local/share/applications/appimagelauncher-lite.desktop"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/appimagelauncher.png"

echo "AppImageLauncher Lite removed from user account." 
exit 0