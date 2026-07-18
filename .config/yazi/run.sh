#!/bin/bash
chmod +x "$1"
exec "$1" --appimage-extract-and-run
