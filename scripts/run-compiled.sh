#!/bin/sh
# run-compiled.sh <example>/cmd/<subexample> [args...]
#
# Compile the example (via build-compiled.sh) and run the native binary,
# forwarding any extra arguments to it.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ $# -ge 1 ] || { echo "usage: $0 <example>/cmd/<subexample> [args...]" >&2; exit 2; }
cmd="$1"; shift

bin="$("$SCRIPT_DIR/build-compiled.sh" "$cmd")"
exec "$bin" "$@"
