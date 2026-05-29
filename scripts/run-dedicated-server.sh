#!/usr/bin/env bash
# Launch a headless dedicated server from a repo clone.
#
# Usage:
#   ./scripts/run-dedicated-server.sh [options] [--] [extra engine args...]
#
# Options:
#   --map NAME       Map to load (default: nzp_asylum)
#   --port PORT      UDP port (default: 27500, passed as +port)
#   --maxplayers N   Max players (default: 4)
#   -h, --help       Show help

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

MAP="${OD_MAP:-nzp_asylum}"
PORT="${OD_PORT:-27500}"
MAXPLAYERS="${OD_MAXPLAYERS:-4}"
EXTRA_ARGS=()

die() {
	echo "ERROR: $*" >&2
	exit 1
}

show_help() {
	cat <<'EOF'
Run Operation Deadfall as a dedicated server (no window).

Requires nzp/ next to the repo or in the parent folder (same as run_game.sh).

Examples:
  ./scripts/run-dedicated-server.sh
  ./scripts/run-dedicated-server.sh --map nzp_asylum --maxplayers 8
  ./scripts/run-dedicated-server.sh -- +sv_public 1

Docker alternative: docker compose up --build (see HOSTING.md).
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--map)
			MAP="${2:-}"
			[[ -n "$MAP" ]] || die "--map requires a name"
			shift 2
			;;
		--port)
			PORT="${2:-}"
			[[ -n "$PORT" ]] || die "--port requires a number"
			shift 2
			;;
		--maxplayers)
			MAXPLAYERS="${2:-}"
			[[ -n "$MAXPLAYERS" ]] || die "--maxplayers requires a number"
			shift 2
			;;
		-h|--help)
			show_help
			exit 0
			;;
		--)
			shift
			EXTRA_ARGS+=("$@")
			break
			;;
		-*)
			die "Unknown option: $1 (try --help)"
			;;
		*)
			EXTRA_ARGS+=("$1")
			shift
			;;
	esac
done

if [[ ! -x "$ROOT/run_game.sh" ]]; then
	die "run_game.sh not found; run from the repository root."
fi

echo "==> Dedicated server: map=$MAP port=$PORT maxplayers=$MAXPLAYERS"
echo "    Clients: +connect <this-host>:$PORT"
echo ""

exec "$ROOT/run_game.sh" -- \
	-dedicated -nohome \
	"+map" "$MAP" \
	"+port" "$PORT" \
	"+maxplayers" "$MAXPLAYERS" \
	"${EXTRA_ARGS[@]}"
