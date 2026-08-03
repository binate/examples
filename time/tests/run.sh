#!/bin/sh
# tests/run.sh — the time end-to-end harness. Runs cmd/dates in BOTH compiled and
# interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
#
# The program writes one file in a scratch directory (passed as its argument) to
# read a modification time back, since that is the only way a Binate program can
# learn anything about the present — the library has no clock. Each mode gets its
# own directory, and the program removes what it made. The timestamp itself is
# never printed, only derived facts about it, so the output is still a fixture.
#
# Run from anywhere (it self-locates the repo root):
#   time/tests/run.sh
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
BIN="$(scripts/build-compiled.sh time/cmd/dates)"
"$BIN" "$WORK/scratch-compiled" > "$WORK/compiled.out" 2>&1
scripts/run-interpreted.sh time/cmd/dates "$WORK/scratch-interpreted" \
    > "$WORK/interpreted.out" 2>/dev/null

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

if [ -d "$WORK/scratch-compiled" ] || [ -d "$WORK/scratch-interpreted" ]; then
    echo "FAIL: the program left its scratch directory behind"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "time/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
