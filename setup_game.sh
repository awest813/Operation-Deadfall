#!/usr/bin/env bash
# One-click game setup for Operation Deadfall on Linux.
# Downloads required NZ:P game data if missing, compiles Deadfall QuakeC,
# optionally adds the LibreQuake asset layer, and validates the installation.
# (The engine itself is not built or downloaded here — see the note at the end.)

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

extract_zip() {
	# extract_zip <zipfile> [member-prefix] — uses unzip, bsdtar, or tar, whichever exists.
	# A "dir/*" member is passed to unzip as-is and trimmed to "dir" for tar-style tools.
	local zip_file=$1
	local member=${2:-}
	local tar_member=${member%/\*}
	if command -v unzip >/dev/null 2>&1; then
		if [[ -n "$member" ]]; then
			unzip -q -o "$zip_file" "$member" -d "$ROOT_DIR"
		else
			unzip -q -o "$zip_file" -d "$ROOT_DIR"
		fi
	elif command -v bsdtar >/dev/null 2>&1; then
		if [[ -n "$tar_member" ]]; then
			bsdtar -xf "$zip_file" -C "$ROOT_DIR" "$tar_member"
		else
			bsdtar -xf "$zip_file" -C "$ROOT_DIR"
		fi
	elif command -v tar >/dev/null 2>&1; then
		if [[ -n "$tar_member" ]]; then
			tar -xf "$zip_file" -C "$ROOT_DIR" "$tar_member"
		else
			tar -xf "$zip_file" -C "$ROOT_DIR"
		fi
	else
		echo "ERROR: Need unzip, bsdtar, or tar to extract archives. Please install one." >&2
		return 2
	fi
}

# Step 1: Check or download game assets
if [[ ! -d "$NZP_DIR" ]] || [[ -z "$(ls -A "$NZP_DIR" 2>/dev/null)" ]]; then
	echo
	echo "[1/4] Downloading official NZ:P game data..."
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
	extract_zip "$TMP_ZIP" "nzp/*"
	rm -f "$TMP_ZIP"
	if [[ ! -d "$NZP_DIR" ]]; then
		echo "ERROR: Extraction did not produce an nzp/ folder. Check the downloaded archive." >&2
		exit 1
	fi
	echo "Game assets extracted."
else
	echo
	echo "[1/4] NZ:P game data is already present."
fi

# Step 1b: Deploy placeholder inventory images for gui/ pics the game draws
# but the NZ:P data does not ship (see specs/asset_audit.md).  Never
# overwrites real artwork that is already present.
if [[ -d "$ROOT_DIR/assets/gui" ]]; then
	mkdir -p "$NZP_DIR/gui"
	for img in "$ROOT_DIR"/assets/gui/*.jpg; do
		tgt="$NZP_DIR/gui/$(basename "$img")"
		[[ -f "$tgt" ]] || cp -f "$img" "$tgt"
	done
fi

# Step 2: Compile Deadfall QuakeC bytecode
echo
echo "[2/4] Compiling and deploying Operation Deadfall QuakeC..."
if [[ -x "$BUILD_QC" ]]; then
	if ! "$BUILD_QC"; then
		echo "WARNING: QuakeC compile reported errors; check build/qc/build_logs." >&2
	fi
else
	echo "WARNING: $BUILD_QC not found or not executable; skipping QuakeC build." >&2
fi

# Step 3: Optional LibreQuake layer
if [[ "$WITH_LQ1" -eq 1 && ! -d "$ROOT_DIR/lq1" ]]; then
	echo
	echo "[3/4] Downloading LibreQuake supplementary asset layer..."
	LQ1_ZIP="${TMPDIR:-/tmp}/lq1_mod.zip"
	if command -v curl >/dev/null 2>&1; then
		curl -fSL -o "$LQ1_ZIP" "$LQ1_ZIP_URL"
	else
		wget -O "$LQ1_ZIP" "$LQ1_ZIP_URL"
	fi
	extract_zip "$LQ1_ZIP"
	rm -f "$LQ1_ZIP"
	# mod.zip wraps the gamedir as mod/lq1/ — normalise to lq1/ next to nzp/.
	if [[ ! -d "$ROOT_DIR/lq1" && -d "$ROOT_DIR/mod/lq1" ]]; then
		mv "$ROOT_DIR/mod/lq1" "$ROOT_DIR/lq1"
		rmdir "$ROOT_DIR/mod" 2>/dev/null || true
	fi
	if [[ ! -d "$ROOT_DIR/lq1" ]]; then
		echo "WARNING: Extraction did not produce an lq1/ folder; continuing without LibreQuake." >&2
	else
		echo "LibreQuake layer installed."
	fi
else
	echo
	echo "[3/4] Asset layer check complete."
fi

# Step 4: Validate the installation
echo
echo "[4/4] Validating installation..."
if [[ ! -f "$NZP_DIR/progs.dat" ]]; then
	echo "WARNING: $NZP_DIR/progs.dat is missing — the QuakeC compile/deploy step did not succeed." >&2
	echo "         The game will fall back to stock NZ:P bytecode until it is built." >&2
fi
if ! ls "$ROOT_DIR"/engine/dist/*/nzportable* "$ROOT_DIR"/engine/release/nzportable* >/dev/null 2>&1; then
	echo "NOTE: No engine binary found under engine/release/ or engine/dist/. This setup" >&2
	echo "      script does not build the engine; build one with:" >&2
	echo "        ./scripts/install-linux-build-deps.sh && ./build.sh --preset linux64 --package" >&2
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
