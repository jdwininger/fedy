#!/bin/bash
set -e

REMOTE=flathub
APP_ID=cc.arduino.IDE2

flatpak install --user -y "$REMOTE" "$APP_ID"
