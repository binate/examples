#!/bin/sh
# tests/run.sh — the scripting end-to-end harness. Runs the SAME source file
# three ways and checks each against a fixture:
#
#   1. kernel exec   ./cmd/greet/main.bn a b        (the `#!` line does the work)
#   2. bni -x        bin/bnrun cmd/greet/main.bn a b
#   3. compiled      bnc, then run the binary
#
# Legs 1 and 2 must agree exactly — leg 1 is just the kernel arranging leg 2 —
# and both differ from leg 3 in one line: argv[0] names the SCRIPT when running
# from source and the BINARY when compiled, which the program reports as
# "started from source". Two fixtures, and the harness checks that they differ in
# exactly that one line, so a divergence anywhere else fails.
#
# Leg 1 needs bin/ on PATH, since `#!/usr/bin/env bnrun` resolves the launcher
# there — the same thing a user of this example does.
#
# Run from anywhere (it self-locates the repo root):
#   scripting/tests/run.sh
#
# Exit code: 0 if all three legs match their fixtures, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

SRC="$EXAMPLE_DIR/cmd/greet/main.bn"
want_script="$SCRIPT_DIR/expected/script.txt"
want_compiled="$SCRIPT_DIR/expected/compiled.txt"

fail=0
check() {
    # check <label> <actual-file> <expected-file>
    if [ ! -f "$3" ]; then
        echo "FAIL: $1: no fixture $3"; fail=1; return
    fi
    if ! diff -q "$2" "$3" >/dev/null; then
        echo "FAIL: $1 != fixture"; diff "$3" "$2" | head; fail=1
    fi
}

# The script must be executable for the kernel to honor its `#!` line at all.
if [ ! -x "$SRC" ]; then
    echo "FAIL: $SRC is not executable (the exec bit is what makes it a script)"
    exit 1
fi

PATH="$EXAMPLE_DIR/bin:$PATH" "$SRC" world friend > "$WORK/kernel.out" 2>&1
check "kernel exec" "$WORK/kernel.out" "$want_script"

"$EXAMPLE_DIR/bin/bnrun" "$SRC" world friend > "$WORK/bnrun.out" 2>&1
check "bni -x" "$WORK/bnrun.out" "$want_script"

BIN="$(scripts/build-compiled.sh scripting/cmd/greet)"
"$BIN" world friend > "$WORK/compiled.out" 2>&1
check "compiled" "$WORK/compiled.out" "$want_compiled"

# The two fixtures must differ in exactly one line each way — the argv[0] report.
if [ -f "$want_script" ] && [ -f "$want_compiled" ]; then
    changed="$(diff "$want_script" "$want_compiled" | grep -c '^[<>]' || true)"
    if [ "$changed" -ne 2 ]; then
        echo "FAIL: the script and compiled fixtures differ in $changed lines, not 2"
        diff "$want_script" "$want_compiled" | head
        fail=1
    fi
fi

if [ "$fail" -eq 0 ]; then
    echo "scripting/tests/run.sh: PASS (kernel == bni -x == fixture; compiled == fixture)"
fi
[ "$fail" -eq 0 ]
