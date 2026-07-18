#!/bin/bash
chmod +x "$1"
"$1" --appimage-extract-and-run > /tmp/appimage.log 2>&1
