#!/usr/bin/env bash
# Graphical setup wizard (Linux): dependencies, engine build, launch game.
# From repo root: ./install_gui.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

die() {
	echo "ERROR: $*" >&2
	exit 1
}

run_tk_gui() {
	exec python3 "$ROOT/scripts/install_gui.py"
}

run_zenity_menu() {
	local choice
	choice="$(zenity --list --radiolist --height=320 --width=520 \
		--title="Operation Deadfall — Setup" \
		--text="Choose an action (install python3-tk for the full graphical installer):" \
		--column="" --column="Action" \
		FALSE "Install Linux build dependencies (opens terminal for sudo)" \
		FALSE "Build engine (linux64, packaged to engine/dist/)" \
		FALSE "Build engine with Docker (linux64, packaged)" \
		FALSE "Run game (./run_game.sh)" \
		FALSE "Open repository folder in file manager" \
		2>/dev/null)" || exit 0

	case "$choice" in
		*"Install Linux build"*)
			if command -v x-terminal-emulator >/dev/null 2>&1; then
				x-terminal-emulator -e bash -lc "cd $(printf %q "$ROOT") && ./scripts/install-linux-build-deps.sh; echo; read -rp 'Press Enter… ' _"
			elif command -v gnome-terminal >/dev/null 2>&1; then
				gnome-terminal -- bash -lc "cd $(printf %q "$ROOT") && ./scripts/install-linux-build-deps.sh; echo; read -rp 'Press Enter… ' _"
			else
				zenity --error --text="No terminal found. Run: ./scripts/install-linux-build-deps.sh"
			fi
			;;
		*"Build engine (linux64"*)
			(
				cd "$ROOT"
				./build.sh --preset linux64 --package
			) 2>&1 | zenity --text-info --title="Build log" --width=700 --height=500 || true
			;;
		*"Docker"*)
			(
				cd "$ROOT"
				./build.sh --preset linux64 --docker --package
			) 2>&1 | zenity --text-info --title="Docker build log" --width=700 --height=500 || true
			;;
		*"Run game"*)
			exec "$ROOT/run_game.sh"
			;;
		*"Open repository"*)
			xdg-open "$ROOT" 2>/dev/null || true
			;;
	esac
}

if [[ "$(uname -s)" != Linux ]]; then
	die "This GUI is aimed at Linux. On Windows see README (run_game.cmd, build_engine.cmd)."
fi

if python3 -c "import tkinter" 2>/dev/null; then
	run_tk_gui
fi

if command -v zenity >/dev/null 2>&1; then
	run_zenity_menu
	exit 0
fi

die "Install a GUI toolkit: Debian/Ubuntu sudo apt install python3-tk zenity (either is enough)."
