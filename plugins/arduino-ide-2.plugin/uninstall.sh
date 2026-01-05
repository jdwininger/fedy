#!/bin/bash
set -e

APP_ID=cc.arduino.IDE2

flatpak uninstall --user -y "$APP_ID"
