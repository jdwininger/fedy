#!/bin/bash
if ls "$HOME/Applications/LM Studio"/*.AppImage >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi
