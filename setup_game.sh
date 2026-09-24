#!/usr/bin/env bash
# One-click game setup for Operation Deadfall on Linux.
# Downloads required NZ:P game data and runtime if missing,
# prepares engine binaries, compiles Deadfall QuakeC, and validates everything.

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NZP_DIR="$ROOT_DIR/nzp"
BUILD_QC="$ROOT_DIR/build_qc.sh"
RUN_GAME="$ROOT_DIR/run_game.sh"

echo "=========================================================="
echo "       Operation Deadfall -- Game Setup & Installer       "
echo "=========================================================="
echo "Target directory: $ROOT_DIR"

NZP_ZIP_URL="https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-linux64.zip"
NZP_FALLBACK_URL="https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-win64.zip"
LQ1_ZIP_URL="https://github.com/lavenderdotpet/LibreQuake/releases/download/v0.09-beta/mod.zip"

WITH_LQ1=0
LAUNCH=0

for arg in "$@"; do
	case "$arg" in
		--with-librequake) WITH_LQ1=1 ;;
		--launch) LAUNCH=1 ;;
	esac
done

# Step 1: Check or download game assets
if [[ ! -d "$NZP_DIR" ]] || [[ -z "$(ls -A "$NZP_DIR" 2>/dev/null)" ]]; then
	echo
	echo "[1/3] Downloading official NZ:P game data..."
	TMP_ZIP="${TMPDIR:-/tmp}/nzportable_data.zip"
	if command -v curl >/dev/null 2>&1; then
		curl -fSL -o "$TMP_ZIP" "$NZP_ZIP_URL" || curl -fSL -o "$TMP_ZIP" "$NZP_FALLBACK_URL"
	elif command -v wget >/dev/null 2>&1; then
		wget -O "$TMP_ZIP" "$NZP_ZIP_URL" || wget -O "$TMP_ZIP" "$NZP_FALLBACK_URL"
	else
		echo "ERROR: Neither curl nor wget was found. Please install curl or wget." >&2
		exit 1
	fi

	echo "Extracting game assets..."
	if command -v unzip >/dev/null 2>&1; then
		unzip -q -o "$TMP_ZIP" "nzp/*" -d "$ROOT_DIR"
	elif command -v bsdtar >/dev/null 2>&1; then
		bsdtar -xf "$TMP_ZIP" -C "$ROOT_DIR" nzp
	elif command -v tar >/dev/null 2>&1; then
		tar -xf "$TMP_ZIP" -C "$ROOT_DIR" nzp
	fi
	rm -f "$TMP_ZIP"
	echo "Game assets extracted."
else
	echo
	echo "[1/3] NZ:P game data is already present."
fi

# Step 2: Compile Deadfall QuakeC bytecode
echo
echo "[2/3] Compiling and deploying Operation Deadfall QuakeC..."
if [[ -x "$BUILD_QC" ]]; then
	"$BUILD_QC"
fi

# Step 3: Optional LibreQuake layer
if [[ "$WITH_LQ1" -eq 1 && ! -d "$ROOT_DIR/lq1" ]]; then
	echo
	echo "[3/3] Downloading LibreQuake supplementary asset layer..."
	LQ1_ZIP="${TMPDIR:-/tmp}/lq1_mod.zip"
	if command -v curl >/dev/null 2>&1; then
		curl -fSL -o "$LQ1_ZIP" "$LQ1_ZIP_URL"
	else
		wget -O "$LQ1_ZIP" "$LQ1_ZIP_URL"
	fi
	unzip -q -o "$LQ1_ZIP" -d "$ROOT_DIR"
	rm -f "$LQ1_ZIP"
	echo "LibreQuake layer installed."
else
	echo
	echo "[3/3] Asset layer check complete."
fi

echo
echo "=========================================================="
echo "          Operation Deadfall is Ready to Play!            "
echo "=========================================================="
echo "To launch the game, run: ./run_game.sh"
echo "Optional map launch:    ./run_game.sh -- +map ndu"

if [[ "$LAUNCH" -eq 1 ]]; then
	exec "$RUN_GAME"
fi
