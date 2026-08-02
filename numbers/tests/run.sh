#!/bin/sh
# tests/run.sh — the numbers end-to-end harness. Runs BOTH runnables (cmd/fib and
# cmd/gcd) in BOTH modes and asserts, per runnable,
#   compiled == interpreted == tests/expected/<sub>.txt
# The two share pkg/seq, so this is also the check that one example directory
# serving several commands off one package search root keeps working.
#
# pkg/seq's own behavior is covered by its unit tests (pkg/seq/seq_test.bn); what
# these fixtures pin is the programs' output — the arguments they choose and the
# shape they print.
#
# Run from anywhere (it self-locates the repo root):
#   numbers/tests/run.sh
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
for sub in fib gcd; do
    want="$SCRIPT_DIR/expected/$sub.txt"
    BIN="$(scripts/build-compiled.sh "numbers/cmd/$sub")"
    "$BIN" > "$WORK/$sub.compiled" 2>&1
    scripts/run-interpreted.sh "numbers/cmd/$sub" > "$WORK/$sub.interpreted" 2>/dev/null

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
    echo "numbers/tests/run.sh: PASS (fib, gcd: compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
