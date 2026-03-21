#!/usr/bin/env bash
# build.sh – convenience build script for Operation Deadfall (Linux / macOS hosts)
#
# Usage:
#   ./build.sh [OPTIONS]
#
# Options:
#   --target TARGET   FTE_TARGET value (default: auto-detect from host arch)
#                     Valid values: linux32, linux64, linux_armhf, linux_arm64,
#                                   SDL2 (native SDL2), win32, win64,
#                                   win32_SDL2, win64_SDL2
#   --nosdl           Build without SDL2 (X11/WinAPI direct)
#   --jobs N          Parallel jobs (default: all CPU cores)
#   --docker          Run inside motolegacy/fteqw Docker image
#   --help            Show this message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"

# ---------- defaults ----------------------------------------------------------
USE_DOCKER=0
NOSDL=0
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
TARGET=""

# ---------- argument parsing --------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)   TARGET="$2"; shift 2 ;;
        --nosdl)    NOSDL=1; shift ;;
        --jobs)     JOBS="$2"; shift 2 ;;
        --docker)   USE_DOCKER=1; shift ;;
        --help|-h)
            sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ---------- auto-detect target if not specified --------------------------------
if [[ -z "$TARGET" ]]; then
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)          TARGET="linux64" ;;
        i?86)            TARGET="linux32" ;;
        aarch64|arm64)   TARGET="linux_arm64" ;;
        armv7l|armhf)    TARGET="linux_armhf" ;;
        *)
            echo "WARNING: Unknown architecture '$ARCH', defaulting to linux64." >&2
            TARGET="linux64"
            ;;
    esac
fi

# Apply SDL2 suffix unless --nosdl was requested
if [[ "$NOSDL" -eq 0 ]]; then
    case "$TARGET" in
        linux32|linux64|linux_arm64|linux_armhf)
            FTE_TARGET="SDL2"
            ;;
        win32|win64)
            FTE_TARGET="${TARGET}_SDL2"
            ;;
        *)
            FTE_TARGET="$TARGET"
            ;;
    esac
else
    FTE_TARGET="$TARGET"
fi

# ---------- Docker path -------------------------------------------------------
if [[ "$USE_DOCKER" -eq 1 ]]; then
    echo "==> Running build inside motolegacy/fteqw Docker container..."
    exec docker run --rm \
        -v "$SCRIPT_DIR":/src \
        -w /src/engine \
        motolegacy/fteqw:latest \
        bash -c "make makelibs FTE_TARGET=$FTE_TARGET && \
                 make m-rel FTE_TARGET=$FTE_TARGET FTE_CONFIG=nzportable -j$JOBS"
fi

# ---------- native build ------------------------------------------------------
echo "==> Building Operation Deadfall"
echo "    FTE_TARGET  = $FTE_TARGET"
echo "    FTE_CONFIG  = nzportable"
echo "    Parallel jobs = $JOBS"
echo ""

cd "$ENGINE_DIR"

echo "--> make makelibs FTE_TARGET=$FTE_TARGET"
make makelibs FTE_TARGET="$FTE_TARGET"

echo ""
echo "--> make m-rel FTE_TARGET=$FTE_TARGET FTE_CONFIG=nzportable -j$JOBS"
make m-rel FTE_TARGET="$FTE_TARGET" FTE_CONFIG=nzportable -j"$JOBS"

# SDL Windows link-order workaround (run make a second time if cross-compiling for Windows)
case "$FTE_TARGET" in
    win32_SDL2|win64_SDL2)
        echo ""
        echo "--> (SDL2 Windows link-order workaround) re-running make m-rel..."
        make m-rel FTE_TARGET="$FTE_TARGET" FTE_CONFIG=nzportable -j"$JOBS"
        ;;
esac

echo ""
echo "==> Build complete. Binaries are in: $ENGINE_DIR/release/"
ls -lh "$ENGINE_DIR/release/" 2>/dev/null || true
