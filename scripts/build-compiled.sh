#!/bin/sh
# build-compiled.sh <example>/cmd/<subexample>
#
# Compile a runnable example to a native binary under out/<example>/<sub>.
# Prints the output binary path on stdout (progress goes to stderr), so
# run-compiled.sh can capture it.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

[ $# -eq 1 ] || { echo "usage: $0 <example>/cmd/<subexample>" >&2; exit 2; }
parse_cmd_path "$1"

BNC="$("$SCRIPT_DIR/fetch-builder.sh")"
LIB="$("$SCRIPT_DIR/fetch-builder.sh" --lib)"
set_paths "$EXAMPLE" "$LIB"

mkdir -p "$(dirname "$OUT")"
echo "build-compiled: $1 -> out/$EXAMPLE/$SUB" >&2
"$BNC" -I "$I" -L "$L" --runtime "$RT" -o "$OUT" "$CMDDIR" >&2
echo "$OUT"
