#!/bin/sh
# run-tests-interpreted.sh <example>/<pkg-path>
#
# Run the unit tests (*_test.bn) for one example package through the
# bytecode VM (bni --test) — no native compile, no out/ artifact, e.g.:
#
#   ./scripts/run-tests-interpreted.sh minbasic/pkg/buf
#
# The argument is <example>/<import-path>, as for run-tests-compiled.sh.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

[ $# -eq 1 ] || { echo "usage: $0 <example>/<pkg-path>" >&2; exit 2; }
parse_pkg_path "$1"

BNI="$("$SCRIPT_DIR/fetch-builder.sh" --tool bni)"
LIB="$("$SCRIPT_DIR/fetch-builder.sh" --lib)"
set_paths "$EXAMPLE" "$LIB"

echo "run-tests-interpreted: $1" >&2
exec "$BNI" --test -I "$I" -L "$L" "$PKG"
