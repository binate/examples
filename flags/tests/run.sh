#!/bin/sh
# tests/run.sh — the flags end-to-end harness. Unlike the other examples' single
# fixture, this one runs cmd/greet with SEVERAL argument vectors, because the
# argument vector is the input: one run proves almost nothing about a parser.
#
# Each case is a name, an expected exit status, and a vector; each is run in both
# modes and diffed against tests/expected/<name>.txt.
#
#   defaults   no arguments at all
#   flags      every flag shape at once: alias, --name=value, repeats, a
#              separated list, and trailing positionals
#   stop       `--` ends parsing, so flag-looking tokens become operands
#   unknown    an unrecognized flag: message, usage, and exit 2
#   help       -h prints usage and exits 0
#
# stdout and stderr are captured together here (unlike fmt's harness) because
# nothing writes to stderr — the point is that a parse error is a VALUE the
# program prints itself, not something the library emits.
#
# Run from anywhere (it self-locates the repo root):
#   flags/tests/run.sh
#
# Exit code: 0 if every case matches in both modes, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

BIN="$(scripts/build-compiled.sh flags/cmd/greet)"
fail=0

# run <name> <want-status> [args...]
run() {
    name="$1"; want_status="$2"; shift 2
    want="$SCRIPT_DIR/expected/$name.txt"

    status=0
    "$BIN" "$@" > "$WORK/$name.compiled" 2>&1 || status=$?
    if [ "$status" -ne "$want_status" ]; then
        echo "FAIL: $name: compiled exited $status, want $want_status"; fail=1
    fi

    istatus=0
    scripts/run-interpreted.sh flags/cmd/greet "$@" > "$WORK/$name.interpreted" 2>/dev/null \
        || istatus=$?
    if [ "$istatus" -ne "$want_status" ]; then
        echo "FAIL: $name: interpreted exited $istatus, want $want_status"; fail=1
    fi
    if ! diff -q "$WORK/$name.compiled" "$WORK/$name.interpreted" >/dev/null; then
        echo "FAIL: $name: compiled != interpreted"
        diff "$WORK/$name.compiled" "$WORK/$name.interpreted" | head; fail=1
    fi
    if [ ! -f "$want" ]; then
        echo "FAIL: $name: no fixture expected/$name.txt"; fail=1
    elif ! diff -q "$WORK/$name.compiled" "$want" >/dev/null; then
        echo "FAIL: $name != fixture"; diff "$want" "$WORK/$name.compiled" | head; fail=1
    fi
}

run defaults 0
run flags    0 -v --name=Ada -c 2 -t x -t y -p one:two extra1 extra2
run stop     0 -v -- -n --tag
run unknown  2 --nope
run help     0 -h

if [ "$fail" -eq 0 ]; then
    echo "flags/tests/run.sh: PASS (5 argument vectors, compiled == interpreted == fixture)"
fi
[ "$fail" -eq 0 ]
