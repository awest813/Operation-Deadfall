#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$REPO_DIR/tmp"
ENGINE_DIR="$REPO_DIR/engine"

mkdir -p "$TMP_DIR"

build_and_zip() {
    local script_name="$1"
    local zip_name="$2"
    shift 2

    (cd "$SCRIPT_DIR" && "./$script_name")
    zip -j "$TMP_DIR/$zip_name" "$@"
    rm -rf "$ENGINE_DIR/release"
}

build_and_zip build-nzp-win32.sh pc-nzp-win32.zip \
    "$ENGINE_DIR/release/nzportable-sdl.exe" \
    "$ENGINE_DIR/release/SDL2.dll"

build_and_zip build-nzp-win64.sh pc-nzp-win64.zip \
    "$ENGINE_DIR/release/nzportable-sdl64.exe" \
    "$ENGINE_DIR/release/SDL2.dll"

build_and_zip build-nzp-linux32.sh pc-nzp-linux32.zip \
    "$ENGINE_DIR/release/nzportable32-sdl"

build_and_zip build-nzp-linux64.sh pc-nzp-linux64.zip \
    "$ENGINE_DIR/release/nzportable64-sdl"

build_and_zip build-nzp-linux_armhf.sh pc-nzp-linux_armhf.zip \
    "$ENGINE_DIR/release/nzportablearmhf-sdl"

build_and_zip build-nzp-linux_arm64.sh pc-nzp-linux_arm64.zip \
    "$ENGINE_DIR/release/nzportablearm64-sdl"

build_and_zip build-nzp-web.sh pc-nzp-web.zip \
    "$ENGINE_DIR/release/ftewebgl.wasm" \
    "$ENGINE_DIR/release/ftewebgl.js"
