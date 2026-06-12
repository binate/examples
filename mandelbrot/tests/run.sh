#!/bin/sh
# tests/run.sh — the mandelbrot end-to-end harness. Renders cmd/mandelbrot in
# BOTH compiled and interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
# i.e. the two execution modes agree byte-for-byte with each other AND with the
# committed fixture (the frozen, reviewed picture). The command takes no input
# and no arguments, so one fixture pins the whole program; the escape iteration
# uses only int→float casts, so the picture is identical across modes and hosts.
#
# Run from the examples repo root (optionally with BINATE_BUNDLE set):
#   mandelbrot/tests/run.sh
#
# Exit code: 0 if the picture matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_DIR"

want="$SCRIPT_DIR/expected.txt"
BIN="$(scripts/build-compiled.sh mandelbrot/cmd/mandelbrot)"
"$BIN" > /tmp/mandel_c.out 2>&1
scripts/run-interpreted.sh mandelbrot/cmd/mandelbrot > /tmp/mandel_i.out 2>/dev/null

fail=0
if ! diff -q /tmp/mandel_c.out /tmp/mandel_i.out >/dev/null; then
    echo "FAIL: compiled != interpreted"
    diff /tmp/mandel_c.out /tmp/mandel_i.out | head
    fail=1
fi
if [ ! -f "$want" ]; then
    echo "FAIL: no fixture tests/expected.txt"
    fail=1
elif ! diff -q /tmp/mandel_c.out "$want" >/dev/null; then
    echo "FAIL: compiled != fixture"
    diff "$want" /tmp/mandel_c.out | head
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
