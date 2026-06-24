#!/bin/sh
# examples/run.sh — run each example BASIC program through cmd/run in BOTH
# compiled and interpreted modes and assert
#   compiled == interpreted == expected/<name>.out
# so the programs (and the output the README shows) cannot silently drift.
#
# Run from the examples repo root (optionally with BINATE_BUNDLE set):
#   minbasic/examples/run.sh
#
# Exit code: 0 if every program matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_DIR"

BIN="$(scripts/build-compiled.sh minbasic/cmd/run)"
pass=0
fail=0
for bas in "$SCRIPT_DIR"/*.bas; do
    name="$(basename "${bas%.bas}")"
    want="$SCRIPT_DIR/expected/$name.out"
    "$BIN" "$bas" </dev/null > "/tmp/ex_${name}_c.out" 2>&1 || true
    scripts/run-interpreted.sh minbasic/cmd/run "$bas" </dev/null \
        > "/tmp/ex_${name}_i.out" 2>/dev/null || true
    if [ ! -f "$want" ]; then
        echo "FAIL: $name (no fixture expected/$name.out)"
        fail=$((fail + 1))
        continue
    fi
    if diff -q "/tmp/ex_${name}_c.out" "/tmp/ex_${name}_i.out" >/dev/null \
        && diff -q "/tmp/ex_${name}_c.out" "$want" >/dev/null; then
        echo "PASS: $name"
        pass=$((pass + 1))
    else
        echo "FAIL: $name"
        fail=$((fail + 1))
    fi
done
echo "examples/run.sh: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
