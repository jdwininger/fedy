#!/usr/bin/env bash
set -euo pipefail

INSTALLDIR="$HOME/Applications/TurtleWoW"
DESKTOP_FILE="$HOME/.local/share/applications/turtlewow.desktop"

if [ -x "$INSTALLDIR/TurtleWoW.AppImage" ] || [ -f "$DESKTOP_FILE" ]; then
  exit 0
fi

exit 1
