#!/usr/bin/env bash

set -u

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILDFOLDER=${BUILDFOLDER:-"$ROOT_DIR/build/qc"}
BUILDLOGFOLDER=${BUILDLOGFOLDER:-"$BUILDFOLDER/build_logs"}

mkdir -p "$BUILDFOLDER" "$BUILDLOGFOLDER"

find_tool() {
	local env_name=$1
	local fallback_name=$2
	local legacy_path=${3:-}
	local candidate=""

	candidate=${!env_name:-}
	if [ -n "$candidate" ] && [ -x "$candidate" ]; then
		printf '%s\n' "$candidate"
		return 0
	fi

	if candidate=$(command -v "$fallback_name" 2>/dev/null); then
		printf '%s\n' "$candidate"
		return 0
	fi

	if [ -n "$legacy_path" ] && [ -x "$legacy_path" ]; then
		printf '%s\n' "$legacy_path"
		return 0
	fi

	return 1
}

FTEQCC=${FTEQCC:-}
if [ -z "$FTEQCC" ]; then
	FTEQCC=$(find_tool FTEQCC fteqcc "$ROOT_DIR/engine/qclib/fteqcc.bin" || true)
fi

FTEQW=${FTEQW:-}
if [ -z "$FTEQW" ]; then
	FTEQW=$(find_tool FTEQW fteqw "$ROOT_DIR/fteqw64" || true)
fi

QSS=${QSS:-}
if [ -z "$QSS" ]; then
	QSS=$(find_tool QSS quakespasm-spiked-linux64 "" || true)
fi

run_compile() {
	local module_dir=$1
	local src_file=$2
	local log_name=$3
	local description=$4

	if [ -z "$FTEQCC" ]; then
		echo "Skipping $description (FTEQCC not found)."
		return 1
	fi

	echo -n "Building $description... "
	(
		cd "$module_dir" &&
		"$FTEQCC" -srcfile "$src_file"
	) >"$BUILDLOGFOLDER/$log_name" 2>&1

	if [ $? -eq 0 ]; then
		echo "done"
		return 0
	fi

	echo "failed (see $BUILDLOGFOLDER/$log_name)"
	return 1
}

copy_if_exists() {
	local source_path=$1
	local destination_dir=$2

	if [ -e "$source_path" ]; then
		cp "$source_path" "$destination_dir/"
	fi
}

echo "--- QC builds ---"
echo "Artifacts: $BUILDFOLDER"
echo "Logs:      $BUILDLOGFOLDER"

if [ -n "$FTEQW" ]; then
	echo "Optional defs generation enabled via FTEQW: $FTEQW"
else
	echo "Optional defs generation skipped (FTEQW not found)."
fi

if [ -n "$QSS" ]; then
	echo "Optional QSS defs generation enabled via: $QSS"
else
	echo "Optional QSS defs generation skipped (QSS not found)."
fi

run_compile "$ROOT_DIR/quakec/deadfall" "progs.src" "deadfall-progs.txt" "deadfall server QC"
run_compile "$ROOT_DIR/quakec/deadfall" "csprogs.src" "deadfall-csprogs.txt" "deadfall CSQC"

copy_if_exists "$ROOT_DIR/quakec/qwprogs.dat" "$BUILDFOLDER"
copy_if_exists "$ROOT_DIR/quakec/csprogs.dat" "$BUILDFOLDER"

if [ -d "$ROOT_DIR/quakec/csaddon/src" ]; then
	run_compile "$ROOT_DIR/quakec/csaddon/src" "csaddon.src" "csaddon.txt" "csaddon"
	copy_if_exists "$ROOT_DIR/quakec/csaddon/csaddon.dat" "$BUILDFOLDER"
	if [ -e "$ROOT_DIR/quakec/csaddon/csaddon.dat" ] && command -v zip >/dev/null 2>&1; then
		(
			cd "$ROOT_DIR/quakec/csaddon" &&
			zip -q9 "$BUILDFOLDER/csaddon.pk3" csaddon.dat
		)
	fi
fi

if [ -d "$ROOT_DIR/quakec/menusys" ]; then
	run_compile "$ROOT_DIR/quakec/menusys" "menu.src" "menusys.txt" "menusys"
	copy_if_exists "$ROOT_DIR/quakec/menu.dat" "$BUILDFOLDER"
	if [ -e "$ROOT_DIR/quakec/menu.dat" ] && command -v zip >/dev/null 2>&1; then
		(
			cd "$ROOT_DIR/quakec" &&
			zip -q9 "$BUILDFOLDER/menusys.pk3" menu.dat
		)
	fi
fi

if [ -z "$FTEQCC" ]; then
	cat <<'EOF'
No FTEQCC compiler was found.
Set FTEQCC=/path/to/fteqcc or build the bundled compiler with:
  make -C engine/qclib qcc
EOF
	exit 1
fi
