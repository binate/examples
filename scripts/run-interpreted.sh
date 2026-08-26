#!/bin/sh
# run-interpreted.sh <example>/cmd/<subexample> [args...]
#
# Run a runnable example through the bytecode VM (bni) — no native
# compile, no out/ artifact. Extra arguments are forwarded to the
# program.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

[ $# -ge 1 ] || { echo "usage: $0 <example>/cmd/<subexample> [args...]" >&2; exit 2; }
parse_cmd_path "$1"; shift

BNI="$("$SCRIPT_DIR/fetch-builder.sh" --tool bni)"
LIB="$("$SCRIPT_DIR/fetch-builder.sh" --lib)"
set_paths "$EXAMPLE" "$LIB"

echo "run-interpreted: $EXAMPLE/cmd/$SUB" >&2
# `--` ends bni's own flags, and everything after the MAIN package is already
# the program's argv. So the separator goes BEFORE the package (it guards a path
# that starts with `-`); placing it after would hand the program a literal `--`
# as its first argument. The compiled binary takes the arguments directly, so
# this keeps `run prog.bas` working identically in both modes.
exec "$BNI" -I "$I" -L "$L" -- "$CMDDIR" "$@"
