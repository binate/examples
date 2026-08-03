#!/bin/sh
# tests/run.sh — the interfaces end-to-end harness. Runs cmd/records in BOTH compiled
# and interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
#
# Interface dispatch is where the two backends could most easily diverge: the
# compiler resolves a call through a vtable it lays out, the VM through one it
# builds at load time, and both have to reach the same method — including for a
# type declared in the command rather than in the library it is handed to. A
# byte-identical fixture across both is the check.
#
# The program takes no input and no arguments.
#
# Run from anywhere (it self-locates the repo root):
#   interfaces/tests/run.sh
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
BIN="$(scripts/build-compiled.sh interfaces/cmd/demo)"
"$BIN" > "$WORK/compiled.out" 2>&1
scripts/run-interpreted.sh interfaces/cmd/demo > "$WORK/interpreted.out" 2>/dev/null

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
    echo "interfaces/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
