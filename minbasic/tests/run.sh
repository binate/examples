#!/bin/sh
# tests/run.sh — the minbasic NBS conformance/regression harness. For every
# vendored NBS Minimal BASIC program in tests/nbs/, run it through cmd/run in
# BOTH compiled and interpreted modes and assert
#   compiled == interpreted == tests/expected/<name>.out
# i.e. the two execution modes agree byte-for-byte with each other AND with the
# committed fixture (the frozen, reviewed minbasic output — see tests/README.md).
#
# Run from the examples repo root with BINATE_BUNDLE set, e.g.:
#   BINATE_BUNDLE=.../bundle minbasic/tests/run.sh
#
# Exit code: 0 if every program matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_DIR"

BIN="$(scripts/build-compiled.sh minbasic/cmd/run)"

pass=0
fail=0
for bas in "$SCRIPT_DIR"/nbs/*.BAS; do
    name="$(basename "${bas%.BAS}")"
    want="$SCRIPT_DIR/expected/$name.out"
    # The interpreter reads any INPUT replies from stdin and a program text from
    # its file argument, so </dev/null guarantees a deterministic, input-free run.
    "$BIN" "$bas" </dev/null > "/tmp/nbs_${name}_c.out" 2>&1 || true
    scripts/run-interpreted.sh minbasic/cmd/run "$bas" </dev/null \
        > "/tmp/nbs_${name}_i.out" 2>/dev/null || true
    if [ ! -f "$want" ]; then
        echo "FAIL: $name (no fixture tests/expected/$name.out)"
        fail=$((fail + 1))
        continue
    fi
    if diff -q "/tmp/nbs_${name}_c.out" "/tmp/nbs_${name}_i.out" >/dev/null \
        && diff -q "/tmp/nbs_${name}_c.out" "$want" >/dev/null; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name"
        if ! diff -q "/tmp/nbs_${name}_c.out" "/tmp/nbs_${name}_i.out" >/dev/null; then
            echo "      compiled != interpreted"
        fi
        if ! diff -q "/tmp/nbs_${name}_c.out" "$want" >/dev/null; then
            echo "      compiled != fixture"
        fi
        fail=$((fail + 1))
    fi
done

echo "tests/run.sh: $pass passed, $fail failed (of $((pass + fail)))"
[ "$fail" -eq 0 ]
