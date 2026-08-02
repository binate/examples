#!/bin/sh
# tests/run.sh — the hello end-to-end harness. Runs cmd/hello in BOTH compiled
# and interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
# There is nothing to get wrong in the program itself; what this pins is that the
# smallest possible Binate program still builds, links, and runs the same way
# through both backends — the first thing a toolchain change would break.
#
# Run from anywhere (it self-locates the repo root):
#   hello/tests/run.sh
#
# Exit code: 0 if the two modes and the fixture agree, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

want="$SCRIPT_DIR/expected.txt"
BIN="$(scripts/build-compiled.sh hello/cmd/hello)"
"$BIN" > "$WORK/compiled.out" 2>&1
scripts/run-interpreted.sh hello/cmd/hello > "$WORK/interpreted.out" 2>/dev/null

fail=0
if ! diff -q "$WORK/compiled.out" "$WORK/interpreted.out" >/dev/null; then
    echo "FAIL: compiled != interpreted"
    diff "$WORK/compiled.out" "$WORK/interpreted.out" | head
    fail=1
fi
if [ ! -f "$want" ]; then
    echo "FAIL: no fixture tests/expected.txt"
    fail=1
elif ! diff -q "$WORK/compiled.out" "$want" >/dev/null; then
    echo "FAIL: compiled != fixture"
    diff "$want" "$WORK/compiled.out" | head
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "hello/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
