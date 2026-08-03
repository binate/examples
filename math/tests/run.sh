#!/bin/sh
# tests/run.sh — the math end-to-end harness. Runs BOTH runnables (cmd/floats and
# cmd/bignat) in BOTH modes and asserts, per runnable,
#   compiled == interpreted == tests/expected/<sub>.txt
#
# The two-mode diff is the interesting half here. Floating point is where a
# compiler and an interpreter are most likely to drift apart — a different
# rounding mode, an x87 80-bit intermediate, a libm with its own idea of Pow —
# so a byte-identical fixture across both backends is a real check on the
# dual-mode contract, not a formality. pkg/std/math is pure Binate, so there is
# no libm to disagree with.
#
# Neither program takes input or arguments; every printed value is derived from
# constants.
#
# Run from anywhere (it self-locates the repo root):
#   math/tests/run.sh
#
# Exit code: 0 if every runnable matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

fail=0
for sub in floats bignat; do
    want="$SCRIPT_DIR/expected/$sub.txt"
    BIN="$(scripts/build-compiled.sh "math/cmd/$sub")"
    "$BIN" > "$WORK/$sub.compiled" 2>&1
    scripts/run-interpreted.sh "math/cmd/$sub" > "$WORK/$sub.interpreted" 2>/dev/null

    if ! diff -q "$WORK/$sub.compiled" "$WORK/$sub.interpreted" >/dev/null; then
        echo "FAIL: $sub: compiled != interpreted"
        diff "$WORK/$sub.compiled" "$WORK/$sub.interpreted" | head
        fail=1
    fi
    if [ ! -f "$want" ]; then
        echo "FAIL: $sub: no fixture expected/$sub.txt"
        fail=1
    elif ! diff -q "$WORK/$sub.compiled" "$want" >/dev/null; then
        echo "FAIL: $sub: compiled != fixture"
        diff "$want" "$WORK/$sub.compiled" | head
        fail=1
    fi
done

if [ "$fail" -eq 0 ]; then
    echo "math/tests/run.sh: PASS (floats, bignat: compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
