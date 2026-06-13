#!/bin/sh
# tests/run.sh — the generics end-to-end harness. Runs cmd/demo in BOTH compiled
# and interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
# i.e. the two execution modes agree byte-for-byte with each other AND with the
# committed fixture. The demo takes no input and no arguments, so one fixture
# pins the whole program.
#
# Run from the examples repo root (optionally with BINATE_BUNDLE set):
#   generics/tests/run.sh
#
# Exit code: 0 if the output matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_DIR"

want="$SCRIPT_DIR/expected.txt"
BIN="$(scripts/build-compiled.sh generics/cmd/demo)"
"$BIN" > /tmp/generics_c.out 2>&1
scripts/run-interpreted.sh generics/cmd/demo > /tmp/generics_i.out 2>/dev/null

fail=0
if ! diff -q /tmp/generics_c.out /tmp/generics_i.out >/dev/null; then
    echo "FAIL: compiled != interpreted"
    diff /tmp/generics_c.out /tmp/generics_i.out | head
    fail=1
fi
if [ ! -f "$want" ]; then
    echo "FAIL: no fixture tests/expected.txt"
    fail=1
elif ! diff -q /tmp/generics_c.out "$want" >/dev/null; then
    echo "FAIL: compiled != fixture"
    diff "$want" /tmp/generics_c.out | head
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
