#!/bin/bash
set -e

# Install Arduino IDE 2 AppImage into user's Applications folder
INSTALL_DIR="$HOME/Applications/ArduinoIDE2"
APPIMAGE="$INSTALL_DIR/arduino-ide.AppImage"
ICON_DEST="$HOME/.local/share/icons/hicolor/256x256/apps/arduino-ide-2.png"
DESKTOP_FILE="$HOME/.local/share/applications/arduino-ide-2.desktop"

mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$ICON_DEST")"
mkdir -p "$(dirname "$DESKTOP_FILE")"

APPIMAGE_URL="https://github.com/arduino/arduino-ide/releases/latest/download/arduino-ide_Linux_64bit.AppImage"

echo "Downloading Arduino IDE 2..."
wget -O "$APPIMAGE" "$APPIMAGE_URL"
chmod +x "$APPIMAGE"

# Try to extract an icon from the AppImage; fallback to bundled svg
pushd "$INSTALL_DIR" > /dev/null
"$APPIMAGE" --appimage-extract >/dev/null 2>&1 || true
if [ -f "squashfs-root/.DirIcon" ]; then
    mv "squashfs-root/.DirIcon" "$ICON_DEST"
    rm -rf squashfs-root
else
    # Use repo-provided icon if available
    cp "$(dirname "${BASH_SOURCE[0]}")/arduino.svg" "$ICON_DEST" 2>/dev/null || true
fi
popd > /dev/null

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=Arduino IDE 2
Comment=Arduino IDE 2
Exec="$APPIMAGE" %U
Icon=$ICON_DEST
Type=Application
Categories=Development;IDE;
Terminal=false
StartupWMClass=Arduino
EOF

echo "Arduino IDE 2 installed to $APPIMAGE"
