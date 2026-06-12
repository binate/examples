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

# Programs listed in tests/SKIP are not run (see that file and tests/README.md
# for why). skip_reason echoes a program's skip reason, or nothing if it runs.
SKIP_FILE="$SCRIPT_DIR/SKIP"
skip_reason() {
    [ -f "$SKIP_FILE" ] || return 0
    awk -v n="$1" '
        /^[[:space:]]*#/ { next }
        /^[[:space:]]*$/ { next }
        $1 == n { $1 = ""; sub(/^[[:space:]]+/, ""); print; exit }
    ' "$SKIP_FILE"
}

pass=0
fail=0
skip=0
for bas in "$SCRIPT_DIR"/nbs/*.BAS; do
    name="$(basename "${bas%.BAS}")"
    reason="$(skip_reason "$name")"
    if [ -n "$reason" ]; then
        echo "SKIP: $name ($reason)"
        skip=$((skip + 1))
        continue
    fi
    want="$SCRIPT_DIR/expected/$name.out"
    # A program that reads INPUT draws its replies from stdin; a matching
    # input/<name>.in file supplies a canned, deterministic reply stream. Programs
    # with no INPUT (the common case) have no such file and run on /dev/null. The
    # program text always comes from the file argument, so stdin is free for INPUT.
    in="$SCRIPT_DIR/input/$name.in"
    [ -f "$in" ] || in=/dev/null
    "$BIN" "$bas" <"$in" > "/tmp/nbs_${name}_c.out" 2>&1 || true
    scripts/run-interpreted.sh minbasic/cmd/run "$bas" <"$in" \
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

echo "tests/run.sh: $pass passed, $fail failed, $skip skipped (of $((pass + fail + skip)))"
[ "$fail" -eq 0 ]
