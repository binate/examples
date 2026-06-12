#!/bin/sh
# run-tests-compiled.sh <example>/<pkg-path>
#
# Compile and run the unit tests (*_test.bn) for one example package via
# the toolchain's compiler (bnc --test), e.g.:
#
#   ./scripts/run-tests-compiled.sh minbasic/pkg/buf
#
# The argument is <example>/<import-path>: the example directory is the
# package search root (so minbasic/pkg/buf is imported as "pkg/buf"),
# exactly as for build-compiled.sh. bnc --test builds a test binary; we
# run it and propagate its pass/fail exit code.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

[ $# -eq 1 ] || { echo "usage: $0 <example>/<pkg-path>" >&2; exit 2; }
parse_pkg_path "$1"

BNC="$("$SCRIPT_DIR/fetch-builder.sh")"
LIB="$("$SCRIPT_DIR/fetch-builder.sh" --lib)"
set_paths "$EXAMPLE" "$LIB"

bdir="$(mktemp -d "${TMPDIR:-/tmp}/binate-test.XXXXXX")"
trap 'rm -rf "$bdir"' EXIT INT TERM

echo "run-tests-compiled: $1" >&2
# bnc --test prints the test-binary path on stdout; on a compile error it
# exits non-zero and the captured text is the diagnostic, not a binary.
testbin="$("$BNC" --test -I "$I" -L "$L" --runtime "$RT" --build-dir "$bdir" "$PKG" 2>&1)" || true
if [ ! -x "$testbin" ]; then
    printf '%s\n' "$testbin" >&2
    echo "run-tests-compiled: compile failed for $1" >&2
    exit 1
fi
"$testbin"
