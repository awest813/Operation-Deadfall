#!/usr/bin/env bash
# Launch from a repo clone: put nzp/ next to the repo root, then ./run_game.sh
# (uses -basedir so the engine finds nzp/ without copying binaries).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

USE_DIST=""
BINARY_OVERRIDE=""
GAME_ARGS=()
BASEDIR=""
NZP_DIR=""

die() {
	echo "ERROR: $*" >&2
	exit 1
}

show_help() {
	cat <<'EOF'
Launch Operation Deadfall from a clone of this repo.

Usage:
  ./run_game.sh [options] [--] [engine arguments...]

Options:
  --dist LABEL     Use engine from engine/dist/LABEL/ (e.g. linux64)
  --binary PATH    Use this executable instead of auto-detecting
  -h, --help       Show this help

Put nzp/ inside the repo root or in the parent folder (next to the repo). See README.md.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--dist)
			USE_DIST="${2:-}"
			[[ -n "$USE_DIST" ]] || die "--dist requires a label (e.g. linux64)"
			shift 2
			;;
		--binary)
			BINARY_OVERRIDE="${2:-}"
			[[ -n "$BINARY_OVERRIDE" ]] || die "--binary requires a path"
			shift 2
			;;
		-h|--help)
			show_help
			exit 0
			;;
		--)
			shift
			GAME_ARGS+=("$@")
			break
			;;
		-*)
			die "Unknown option: $1 (try --help)"
			;;
		*)
			GAME_ARGS+=("$1")
			shift
			;;
	esac
done

resolve_nzp() {
	if [[ -d "$ROOT/nzp" ]]; then
		BASEDIR="$ROOT"
		NZP_DIR="$ROOT/nzp"
		return 0
	fi
	if [[ -d "$ROOT/../nzp" ]]; then
		BASEDIR="$(cd "$ROOT/.." && pwd)"
		NZP_DIR="$BASEDIR/nzp"
		return 0
	fi
	die "Missing nzp/ game data. Expected either:
  $ROOT/nzp
  $(cd "$ROOT/.." && pwd)/nzp
Obtain nzp from NZ:P releases (see README.md Quick Start)."
}

# Optional: LibreQuake free asset layer. If lq1/ sits next to nzp/ (same basedir),
# pass -game lq1 so FTEQW loads LibreQuake's BSD-licensed Quake assets alongside nzp/.
# Download from https://github.com/lavenderdotpet/LibreQuake/releases (mod.zip -> lq1/).
LQ1_ARGS=()
resolve_lq1() {
	if [[ -n "$BASEDIR" && -d "$BASEDIR/lq1" ]]; then
		LQ1_ARGS=(-game lq1)
		echo "LibreQuake data found at $BASEDIR/lq1 — loading as supplementary asset layer."
	fi
}

resolve_nzp
resolve_lq1

pick_linux_binary() {
	local candidates=()
	if [[ -n "$BINARY_OVERRIDE" ]]; then
		[[ -x "$BINARY_OVERRIDE" || -f "$BINARY_OVERRIDE" ]] || die "Not found or not executable: $BINARY_OVERRIDE"
		echo "$BINARY_OVERRIDE"
		return 0
	fi

	if [[ -n "$USE_DIST" ]]; then
		local d="$ROOT/engine/dist/$USE_DIST"
		[[ -d "$d" ]] || die "engine/dist/$USE_DIST not found. Build with: ./build.sh --preset $USE_DIST --package"
		case "$(uname -m)" in
			aarch64|arm64)
				candidates+=("$d/nzportable-sdl2" "$d/nzportablearm64-sdl" "$d/nzportablearm64" "$d/nzportable64-sdl")
				;;
			armv7l|armhf)
				candidates+=("$d/nzportable-sdl2" "$d/nzportablearmhf-sdl" "$d/nzportablearmhf" "$d/nzportable64-sdl")
				;;
			*)
				candidates+=("$d/nzportable-sdl2" "$d/nzportable64-sdl" "$d/nzportable64" "$d/nzportablearm64-sdl")
				;;
		esac
	fi

	case "$(uname -m)" in
		aarch64|arm64)
			candidates+=(
				"$ROOT/engine/release/nzportablearm64-sdl"
				"$ROOT/engine/release/nzportable-sdl2"
				"$ROOT/engine/release/nzportablearm64"
				"$ROOT/engine/release/nzportable64-sdl"
			)
			;;
		armv7l|armhf)
			candidates+=(
				"$ROOT/engine/release/nzportablearmhf-sdl"
				"$ROOT/engine/release/nzportable-sdl2"
				"$ROOT/engine/release/nzportablearmhf"
				"$ROOT/engine/release/nzportable64-sdl"
			)
			;;
		*)
			candidates+=(
				"$ROOT/engine/release/nzportable64-sdl"
				"$ROOT/engine/release/nzportable-sdl2"
				"$ROOT/engine/release/nzportablearm64-sdl"
				"$ROOT/engine/release/nzportable64"
			)
			;;
	esac

	local b
	for b in "${candidates[@]}"; do
		if [[ -x "$b" ]]; then
			echo "$b"
			return 0
		fi
	done

	die "No Linux engine binary found under engine/release/ or engine/dist/.
Build one with: ./build.sh --preset linux64 --package
Or pass an explicit path: ./run_game.sh --binary /path/to/nzportable64-sdl"
}

case "$(uname -s)" in
	Darwin)
		die "macOS is not supported for this engine. See README.md."
		;;
	MINGW*|MSYS*|CYGWIN*)
		die "On Windows, run nzportable-sdl64.exe from engine\\\\release or engine\\\\dist\\\\win11 next to nzp\\\\.
See RUNNING_THE_GAME.md."
		;;
	Linux)
		EXE="$(pick_linux_binary)"
		exec "$EXE" -basedir "$BASEDIR" "${LQ1_ARGS[@]}" "${GAME_ARGS[@]}"
		;;
	*)
		die "Unsupported OS: $(uname -s)"
		;;
esac
