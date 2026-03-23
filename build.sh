#!/usr/bin/env bash
# build.sh – convenience build script for Operation Deadfall (Linux / macOS hosts)
#
# Usage:
#   ./build.sh [OPTIONS]
#
# Recommended presets:
#   ./build.sh --preset linux64           # native Linux 64-bit SDL2 build
#   ./build.sh --preset linux64-nosdl     # native Linux 64-bit X11 build
#   ./build.sh --preset win11 --package   # Windows 11-friendly 64-bit build bundle
#
# Options:
#   --preset NAME      Friendly build preset. Valid values:
#                      linux64, linux64-nosdl, win11, win11-nosdl
#   --target TARGET    Raw FTE_TARGET value (default: auto-detect from host arch)
#                      Valid values: linux32, linux64, linux_armhf, linux_arm64,
#                                    SDL2 (native SDL2), win32, win64,
#                                    win32_SDL2, win64_SDL2
#   --nosdl            Build without SDL2 (X11/WinAPI direct)
#   --jobs N           Parallel jobs (default: all CPU cores)
#   --docker           Run inside motolegacy/fteqw Docker image
#   --package          Copy the finished runnable files into engine/dist/<label>/
#   --help             Show this message

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENGINE_DIR="$SCRIPT_DIR/engine"
DIST_DIR="$ENGINE_DIR/dist"

# ---------- defaults ----------------------------------------------------------
USE_DOCKER=0
NOSDL=0
PACKAGE_OUTPUT=0
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
TARGET=""
PRESET=""
FTE_TARGET=""
OUTPUT_LABEL=""
PRIMARY_ARTIFACT=""
SDL2_DLL=""

show_help() {
    sed -n '/^# Usage:/,/^$/p' "$0" | sed 's/^# \?//'
}

die() {
    echo "ERROR: $*" >&2
    exit 1
}

ensure_docker_build() {
    local docker_cmd="make makelibs FTE_TARGET=$FTE_TARGET && make m-rel FTE_TARGET=$FTE_TARGET FTE_CONFIG=nzportable -j$JOBS"
    case "$FTE_TARGET" in
        win32_SDL2|win64_SDL2)
            docker_cmd+=" && make m-rel FTE_TARGET=$FTE_TARGET FTE_CONFIG=nzportable -j$JOBS"
            ;;
    esac

    echo "==> Running build inside motolegacy/fteqw Docker container..."
    exec docker run --rm         -v "$SCRIPT_DIR":/src         -w /src/engine         motolegacy/fteqw:latest         bash -lc "$docker_cmd"
}

resolve_settings() {
    if [[ -n "$PRESET" ]]; then
        case "$PRESET" in
            linux64)
                TARGET="linux64"
                NOSDL=0
                ;;
            linux64-nosdl)
                TARGET="linux64"
                NOSDL=1
                ;;
            win11)
                TARGET="win64"
                NOSDL=0
                ;;
            win11-nosdl)
                TARGET="win64"
                NOSDL=1
                ;;
            *)
                die "Unknown preset '$PRESET'. Valid presets: linux64, linux64-nosdl, win11, win11-nosdl"
                ;;
        esac
    fi

    if [[ -z "$TARGET" ]]; then
        local arch
        arch=$(uname -m)
        case "$arch" in
            x86_64) TARGET="linux64" ;;
            i?86) TARGET="linux32" ;;
            aarch64|arm64) TARGET="linux_arm64" ;;
            armv7l|armhf) TARGET="linux_armhf" ;;
            *)
                echo "WARNING: Unknown architecture '$arch', defaulting to linux64." >&2
                TARGET="linux64"
                ;;
        esac
    fi

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

    case "$TARGET:$NOSDL" in
        linux64:0)
            OUTPUT_LABEL="linux64"
            PRIMARY_ARTIFACT="release/nzportable-sdl2"
            ;;
        linux64:1)
            OUTPUT_LABEL="linux64-nosdl"
            PRIMARY_ARTIFACT="release/nzportable"
            ;;
        linux32:0)
            OUTPUT_LABEL="linux32"
            PRIMARY_ARTIFACT="release/nzportable-sdl2"
            ;;
        linux32:1)
            OUTPUT_LABEL="linux32-nosdl"
            PRIMARY_ARTIFACT="release/nzportable"
            ;;
        linux_arm64:0)
            OUTPUT_LABEL="linux_arm64"
            PRIMARY_ARTIFACT="release/nzportable-sdl2"
            ;;
        linux_arm64:1)
            OUTPUT_LABEL="linux_arm64-nosdl"
            PRIMARY_ARTIFACT="release/nzportable"
            ;;
        linux_armhf:0)
            OUTPUT_LABEL="linux_armhf"
            PRIMARY_ARTIFACT="release/nzportable-sdl2"
            ;;
        linux_armhf:1)
            OUTPUT_LABEL="linux_armhf-nosdl"
            PRIMARY_ARTIFACT="release/nzportable"
            ;;
        win64:0)
            OUTPUT_LABEL="win11"
            PRIMARY_ARTIFACT="release/nzportable-sdl64.exe"
            SDL2_DLL="release/SDL2.dll"
            ;;
        win64:1)
            OUTPUT_LABEL="win11-nosdl"
            PRIMARY_ARTIFACT="release/nzportable64.exe"
            ;;
        win32:0)
            OUTPUT_LABEL="win32"
            PRIMARY_ARTIFACT="release/nzportable-sdl.exe"
            SDL2_DLL="release/SDL2.dll"
            ;;
        win32:1)
            OUTPUT_LABEL="win32-nosdl"
            PRIMARY_ARTIFACT="release/nzportable.exe"
            ;;
        *)
            OUTPUT_LABEL="${PRESET:-$TARGET}"
            PRIMARY_ARTIFACT=""
            ;;
    esac
}

create_aliases() {
    case "$TARGET:$NOSDL" in
        linux64:0)
            [[ -f release/nzportable-sdl2 ]] && cp -f release/nzportable-sdl2 release/nzportable64-sdl
            ;;
        linux64:1)
            [[ -f release/nzportable ]] && cp -f release/nzportable release/nzportable64
            ;;
        linux32:0)
            [[ -f release/nzportable-sdl2 ]] && cp -f release/nzportable-sdl2 release/nzportable32-sdl
            ;;
        linux32:1)
            [[ -f release/nzportable ]] && cp -f release/nzportable release/nzportable32
            ;;
        linux_arm64:0)
            [[ -f release/nzportable-sdl2 ]] && cp -f release/nzportable-sdl2 release/nzportablearm64-sdl
            ;;
        linux_arm64:1)
            [[ -f release/nzportable ]] && cp -f release/nzportable release/nzportablearm64
            ;;
        linux_armhf:0)
            [[ -f release/nzportable-sdl2 ]] && cp -f release/nzportable-sdl2 release/nzportablearmhf-sdl
            ;;
        linux_armhf:1)
            [[ -f release/nzportable ]] && cp -f release/nzportable release/nzportablearmhf
            ;;
    esac
}

package_output() {
    local package_dir="$DIST_DIR/$OUTPUT_LABEL"
    [[ -n "$PRIMARY_ARTIFACT" ]] || die "Packaging is only supported for known Linux/Windows presets and targets"
    [[ -f "$PRIMARY_ARTIFACT" ]] || die "Expected build artifact not found: $PRIMARY_ARTIFACT"

    mkdir -p "$package_dir"
    cp -f "$PRIMARY_ARTIFACT" "$package_dir/"
    if [[ -n "$SDL2_DLL" && -f "$SDL2_DLL" ]]; then
        cp -f "$SDL2_DLL" "$package_dir/"
    fi

    cat > "$package_dir/README-BUILD.txt" <<EOF
Operation Deadfall build bundle
===============================

Preset: $OUTPUT_LABEL
Primary artifact: $(basename "$PRIMARY_ARTIFACT")

How to run:
- Put this executable next to your nzp/ game-data folder.
- Linux: launch from a terminal.
- Windows: double-click the .exe or run it from Command Prompt.

See BUILD.md for build instructions and RUNNING_THE_GAME.md for runtime setup.
EOF

    echo ""
    echo "==> Packaged runnable files into: $package_dir"
    ls -lh "$package_dir"
}

# ---------- argument parsing --------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --preset)   PRESET="${2:-}"; shift 2 ;;
        --target)   TARGET="${2:-}"; shift 2 ;;
        --nosdl)    NOSDL=1; shift ;;
        --jobs)     JOBS="${2:-}"; shift 2 ;;
        --docker)   USE_DOCKER=1; shift ;;
        --package)  PACKAGE_OUTPUT=1; shift ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *) die "Unknown option: $1" ;;
    esac
done

resolve_settings

# ---------- Docker path -------------------------------------------------------
if [[ "$USE_DOCKER" -eq 1 ]]; then
    ensure_docker_build
fi

# ---------- native build ------------------------------------------------------
echo "==> Building Operation Deadfall"
echo "    Preset        = ${PRESET:-custom}"
echo "    Target        = $TARGET"
echo "    FTE_TARGET    = $FTE_TARGET"
echo "    FTE_CONFIG    = nzportable"
echo "    Parallel jobs = $JOBS"
echo "    Package bundle = $PACKAGE_OUTPUT"
echo ""

cd "$ENGINE_DIR"

echo "--> make makelibs FTE_TARGET=$FTE_TARGET"
make makelibs FTE_TARGET="$FTE_TARGET"

echo ""
echo "--> make m-rel FTE_TARGET=$FTE_TARGET FTE_CONFIG=nzportable -j$JOBS"
make m-rel FTE_TARGET="$FTE_TARGET" FTE_CONFIG=nzportable -j"$JOBS"

case "$FTE_TARGET" in
    win32_SDL2|win64_SDL2)
        echo ""
        echo "--> (SDL2 Windows link-order workaround) re-running make m-rel..."
        make m-rel FTE_TARGET="$FTE_TARGET" FTE_CONFIG=nzportable -j"$JOBS"

        if [[ "$FTE_TARGET" == "win64_SDL2" ]]; then
            SDL2_SOURCE="libs-x86_64-w64-mingw32/SDL2-2.30.7/x86_64-w64-mingw32/bin/SDL2.dll"
        else
            SDL2_SOURCE="libs-i686-w64-mingw32/SDL2-2.30.7/i686-w64-mingw32/bin/SDL2.dll"
        fi
        if [[ -f "$SDL2_SOURCE" ]]; then
            echo "--> Copying SDL2.dll to release/"
            cp -f "$SDL2_SOURCE" release/
        else
            echo "WARNING: SDL2.dll not found at $SDL2_SOURCE – users will need to supply it manually." >&2
        fi
        ;;
esac

create_aliases

echo ""
echo "==> Build complete. Binaries are in: $ENGINE_DIR/release/"
ls -lh "$ENGINE_DIR/release/" 2>/dev/null || true

if [[ "$PACKAGE_OUTPUT" -eq 1 ]]; then
    package_output
fi
