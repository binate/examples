#!/bin/sh
# tests/run.sh — the processes end-to-end harness. Runs cmd/spawn in BOTH
# compiled and interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
#
# The fixture interleaves two programs' output: the children write to the SAME
# stdout this process has (the API has no capture), so `hello from the child`
# lands between the parent's own lines. That order is not a race — process.Run
# waits for the child, so a child's output necessarily precedes the parent's
# report of it.
#
# The children are `/bin/echo` and `sh`, which every POSIX host has (this harness
# is itself a /bin/sh script), so there is nothing to skip on. Nothing depends on
# a host-specific path: the one place a path would differ (LookPath's result for
# `sh`, /bin/sh vs /usr/bin/sh) is reported as a shape, not printed.
#
# Run from anywhere (it self-locates the repo root):
#   processes/tests/run.sh
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
BIN="$(scripts/build-compiled.sh processes/cmd/spawn)"
"$BIN" > "$WORK/compiled.out" 2>&1
scripts/run-interpreted.sh processes/cmd/spawn > "$WORK/interpreted.out" 2>/dev/null

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
    echo "processes/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
