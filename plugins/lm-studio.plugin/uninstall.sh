#!/bin/bash
set -e

rm -rf /opt/lm-studio
rm -f /usr/share/applications/lm-studio.desktop
rm -f /usr/share/icons/hicolor/256x256/apps/lm-studio.png
gtk-update-icon-cache /usr/share/icons/hicolor || true
