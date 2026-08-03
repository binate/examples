#!/bin/sh
# tests/run.sh — the errors end-to-end harness. Runs cmd/report and asserts
#   compiled == tests/expected.txt
#
# COMPILED ONLY, unlike every other both-modes harness here: `bni` SIGSEGVs on
# errors.Is over a user-defined errors.Error, which this example's ParseError is
# (see ../.skip-default-sweeps). Add the interpreted leg back — the two-way diff
# the other harnesses do — once a toolchain carrying the fix is pinned.
#
# What the fixture pins is the RENDERED text of the error chains — every layer's
# message, in order, as a person would see it. The unit tests check the
# classifications programmatically; this checks that the messages read correctly.
#
# The program takes no input and no arguments; the one path it touches
# (/definitely/not/here.conf) is expected to be absent, which is the point.
#
# Run from anywhere (it self-locates the repo root):
#   errors/tests/run.sh
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
BIN="$(scripts/build-compiled.sh errors/cmd/report)"
"$BIN" > "$WORK/compiled.out" 2>&1

fail=0
if [ ! -f "$want" ]; then
    echo "FAIL: no fixture tests/expected.txt"
    fail=1
elif ! diff -q "$WORK/compiled.out" "$want" >/dev/null; then
    echo "FAIL: compiled != fixture"
    diff "$want" "$WORK/compiled.out" | head
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "errors/tests/run.sh: PASS (compiled == fixture; interpreted leg disabled)"
fi
[ "$fail" -eq 0 ]
