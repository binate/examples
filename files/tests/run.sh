#!/bin/sh
# tests/run.sh — the files end-to-end harness. Runs cmd/tour in BOTH compiled and
# interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
#
# The tour really touches the filesystem, so each mode gets its OWN scratch
# directory, passed as the program's argument: the two runs must not share state,
# and neither may depend on what a previous run left behind. The tour prints only
# derived facts (counts, comparisons, classifications) — never a path, a
# permission bit, or a timestamp — so its output is machine-independent, and it
# sorts directory listings, which os.ReadDir does not.
#
# Run from anywhere (it self-locates the repo root):
#   files/tests/run.sh
#
# Exit code: 0 if the two modes and the fixture agree, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM
mkdir -p "$WORK/scratch-compiled" "$WORK/scratch-interpreted"

want="$SCRIPT_DIR/expected.txt"
BIN="$(scripts/build-compiled.sh files/cmd/tour)"
"$BIN" "$WORK/scratch-compiled" > "$WORK/compiled.out" 2>&1
scripts/run-interpreted.sh files/cmd/tour "$WORK/scratch-interpreted" \
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

# The tour cleans up after itself; if it did not, that is a failure too.
if [ -d "$WORK/scratch-compiled" ] || [ -d "$WORK/scratch-interpreted" ]; then
    echo "FAIL: the tour left its scratch directory behind"
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "files/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
