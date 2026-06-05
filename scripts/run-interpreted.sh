#!/bin/sh
# run-interpreted.sh <example>/cmd/<subexample> [args...]
#
# Run a runnable example through the bytecode VM (bni) — no native
# compile, no out/ artifact. Extra arguments are forwarded to the
# program (see TODO.md re: confirming the bni program-arg convention).
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

[ $# -ge 1 ] || { echo "usage: $0 <example>/cmd/<subexample> [args...]" >&2; exit 2; }
parse_cmd_path "$1"; shift

BNI="$("$SCRIPT_DIR/fetch-builder.sh" --tool bni)"
LIB="$("$SCRIPT_DIR/fetch-builder.sh" --lib)"
set_paths "$EXAMPLE" "$LIB"

echo "run-interpreted: $EXAMPLE/cmd/$SUB" >&2
exec "$BNI" -I "$I" -L "$L" "$CMDDIR" "$@"
