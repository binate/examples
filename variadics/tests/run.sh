#!/bin/sh
# tests/run.sh — the variadics end-to-end harness. Renders cmd/demo in BOTH
# compiled and interpreted modes and asserts
#   compiled == interpreted == tests/expected.txt
# Variadic functions are an ordinary language feature (not FFI), so the two
# execution modes must agree with each other and with the committed fixture. The
# program takes no input and no arguments, so one fixture pins it; every printed
# value is deterministic.
#
# It SKIPS (exit 0) when the resolved bnc predates variadics — which landed after
# bnc-0.0.10 (the pinned BUILDER_VERSION). Until a release ships them, run against
# a main build:  BINATE_BUNDLE=<bundle> variadics/tests/run.sh  (see README.md).
# Once BUILDER_VERSION names a release with variadics, this activates
# automatically — no edit needed (the same builder-gate the CI sweeps use).
#
# Run from anywhere (it self-locates the repo root):
#   variadics/tests/run.sh
#
# Exit code: 0 if the two modes and the fixture agree (or the example is
# skipped), 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

if scripts/builder-gate.sh "$EXAMPLE_DIR"; then
    echo "variadics/tests/run.sh: SKIP — resolved bnc predates variadics — see variadics/README.md"
    exit 0
fi

want="$SCRIPT_DIR/expected.txt"
BIN="$(scripts/build-compiled.sh variadics/cmd/demo)"
"$BIN" > /tmp/variadics_c.out 2>&1
scripts/run-interpreted.sh variadics/cmd/demo > /tmp/variadics_i.out 2>/dev/null

fail=0
if ! diff -q /tmp/variadics_c.out /tmp/variadics_i.out >/dev/null; then
    echo "FAIL: compiled != interpreted"
    diff /tmp/variadics_c.out /tmp/variadics_i.out | head
    fail=1
fi
if [ ! -f "$want" ]; then
    echo "FAIL: no fixture tests/expected.txt"
    fail=1
elif ! diff -q /tmp/variadics_c.out "$want" >/dev/null; then
    echo "FAIL: compiled != fixture"
    diff "$want" /tmp/variadics_c.out | head
    fail=1
fi

if [ "$fail" -eq 0 ]; then
    echo "variadics/tests/run.sh: PASS (compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
