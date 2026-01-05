#!/bin/bash
set -e

rm -rf "$HOME/Applications/ArduinoIDE2"
rm -f "$HOME/.local/share/applications/arduino-ide-2.desktop"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/arduino-ide-2.png"

echo "Arduino IDE 2 removed from user's Applications directory."