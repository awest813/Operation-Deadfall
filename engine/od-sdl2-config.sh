#!/bin/sh
# Wrapper: run the vendored sdl2-config but emit Windows-style paths for clang.
REAL="$(dirname "$0")/libs-x86_64-w64-windows-gnu/SDL2-2.30.7/x86_64-w64-windows-gnu/bin/sdl2-config"
sh "$REAL" "$@" | sed 's|/f/|F:/|g'
