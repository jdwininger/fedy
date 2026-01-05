#!/bin/bash
# Return 0 if any common multimedia codec packages are installed

pkgs=(
  gstreamer1-libav
  ffmpeg
  gstreamer1-plugins-ugly
  gstreamer1-plugins-bad-freeworld
  gstreamer1-plugins-bad-free
  gstreamer1-plugins-good
)

for p in "${pkgs[@]}"; do
  if rpm -q "$p" >/dev/null 2>&1; then
    exit 0
  fi
done

# Fall back: check if ffmpeg binary exists
if command -v ffmpeg >/dev/null 2>&1; then
  exit 0
fi

# Not found
exit 1
