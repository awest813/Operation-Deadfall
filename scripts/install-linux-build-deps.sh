#!/usr/bin/env bash
# Install native build dependencies for ./build.sh on Debian/Ubuntu or Fedora/RHEL.
# Run from the repository root: ./scripts/install-linux-build-deps.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "$(uname -s)" != Linux ]]; then
	echo "This script only supports Linux. On other platforms see BUILD.md." >&2
	exit 1
fi

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	echo "Usage: ./scripts/install-linux-build-deps.sh"
	echo "Installs packages required for a native ./build.sh --preset linux64 build."
	exit 0
fi

APT_PKGS=(
	build-essential gcc make
	libsdl2-dev libgl1-mesa-dev libopenal-dev
	zlib1g-dev libbz2-dev libpng-dev libjpeg-dev
	libfreetype6-dev libvorbis-dev libogg-dev libopus-dev
	libgnutls28-dev libx11-dev libxcursor-dev
	libasound2-dev
)

DNF_PKGS=(
	gcc make SDL2-devel mesa-libGL-devel openal-soft-devel
	zlib-devel bzip2-devel libpng-devel libjpeg-turbo-devel
	freetype-devel libvorbis-devel libogg-devel opus-devel
	gnutls-devel libX11-devel libXcursor-devel
	alsa-lib-devel
)

run_apt() {
	if command -v apt-get >/dev/null 2>&1; then
		if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
			apt-get update
			apt-get install -y "${APT_PKGS[@]}"
		else
			sudo apt-get update
			sudo apt-get install -y "${APT_PKGS[@]}"
		fi
		return 0
	fi
	return 1
}

run_dnf() {
	if command -v dnf >/dev/null 2>&1; then
		if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
			dnf install -y "${DNF_PKGS[@]}"
		else
			sudo dnf install -y "${DNF_PKGS[@]}"
		fi
		return 0
	fi
	return 1
}

echo "==> Installing Operation Deadfall engine build dependencies (Linux)"

if run_apt; then
	echo "==> apt packages installed. You can run: ./build.sh --preset linux64 --package"
	exit 0
fi

if run_dnf; then
	echo "==> dnf packages installed. You can run: ./build.sh --preset linux64 --package"
	exit 0
fi

echo "ERROR: Neither apt-get nor dnf was found. Install the packages listed in BUILD.md for your distro." >&2
exit 1
