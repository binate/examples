#!/bin/sh
# tests/run.sh — the fmt end-to-end harness. Runs cmd/demo in BOTH compiled and
# interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
#
# Formatting is exactly the kind of thing two backends can disagree about — float
# rendering, padding arithmetic, the reflection walk over a struct's fields — so
# a byte-identical fixture across both is the check that matters here.
#
# The two streams are captured SEPARATELY. The fixture is stdout, and stderr is
# checked for the one line the demo deliberately writes there (to show that any
# Writer is a destination). Merging them would work for the compiled leg but not
# the interpreted one, whose runner script prints its own banner to stderr — and
# separate captures make the check sharper anyway: the line must be on stderr,
# not merely somewhere in the output.
#
# Run from anywhere (it self-locates the repo root):
#   fmt/tests/run.sh
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
BIN="$(scripts/build-compiled.sh fmt/cmd/demo)"
"$BIN" > "$WORK/compiled.out" 2> "$WORK/compiled.err"
scripts/run-interpreted.sh fmt/cmd/demo > "$WORK/interpreted.out" 2> "$WORK/interpreted.err"

fail=0
for mode in compiled interpreted; do
    if ! grep -q "^this line went to stderr$" "$WORK/$mode.err"; then
        echo "FAIL: $mode: the demo's stderr line is missing from stderr"
        fail=1
    fi
    if grep -q "^this line went to stderr$" "$WORK/$mode.out"; then
        echo "FAIL: $mode: the stderr line leaked into stdout"
        fail=1
    fi
done
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
    echo "fmt/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
