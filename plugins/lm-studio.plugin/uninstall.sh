#!/bin/bash
set -e

rm -rf "$HOME/Applications/LM Studio"
rm -f "$HOME/.local/share/applications/lm-studio.desktop"
rm -f "$HOME/.local/share/icons/hicolor/256x256/apps/lm-studio.png"

echo "LM Studio removed from user's Applications directory."