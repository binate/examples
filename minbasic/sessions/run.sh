#!/bin/sh
# sessions/run.sh — drive each REPL session script (*.in) through cmd/basic in
# BOTH compiled and interpreted modes and diff each run against its committed
# expected transcript (*.out), asserting compiled == interpreted == fixture.
#
# Run from the examples repo root with BINATE_BUNDLE set, e.g.:
#   BINATE_BUNDLE=.../bundle minbasic/sessions/run.sh
#
# Exit code: 0 if every session matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_DIR"

BIN="$(scripts/build-compiled.sh minbasic/cmd/basic)"

fail=0
for in in "$SCRIPT_DIR"/*.in; do
    name="$(basename "${in%.in}")"
    want="${in%.in}.out"
    "$BIN" < "$in" > "/tmp/sess_${name}_c.out" 2>&1 || true
    scripts/run-interpreted.sh minbasic/cmd/basic < "$in" \
        > "/tmp/sess_${name}_i.out" 2>/dev/null || true
    if diff -q "/tmp/sess_${name}_c.out" "/tmp/sess_${name}_i.out" >/dev/null \
        && diff -q "/tmp/sess_${name}_c.out" "$want" >/dev/null; then
        echo "PASS: $name"
    else
        echo "FAIL: $name"
        fail=1
    fi
done

[ "$fail" -eq 0 ]
