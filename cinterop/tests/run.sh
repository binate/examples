#!/bin/sh
# tests/run.sh — the cinterop end-to-end harness.  Compiles the demo C library
# (csrc/*.c) with the system C compiler, links it into each Binate cmd via bnc's
# --link-after-objs, runs the result, and diffs stdout against the committed
# fixture in tests/expected/<sub>.out.
#
# This example is COMPILED-ONLY (the bytecode VM does no FFI), so — unlike the
# other e2e harnesses — there is no interpreted leg: the check is
#   compiled(<sub>) == tests/expected/<sub>.out
# for each cmd.  The RNG is deterministic (fixed seeds, host-independent output),
# so one fixture per cmd pins the whole program.
#
# It SKIPS (exit 0) rather than fails when there is no C compiler on PATH (set
# $CC to choose one; defaults to cc), so it is safe in a CI sweep on a host
# without one.  Everything else is a real failure — including a resolved bnc too
# old for the C-interop intrinsics, which fails the build with
# "undefined: __c_global" (see cinterop/README.md for the version floor).
#
# Run from anywhere (it self-locates the repo root):
#   cinterop/tests/run.sh
#
# Exit code: 0 if every cmd matches its fixture (or the example is skipped),
# 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

skip() { echo "cinterop/tests/run.sh: SKIP — $1"; exit 0; }

CC="${CC:-cc}"
command -v "$CC" >/dev/null 2>&1 || skip "no C compiler on PATH (set \$CC)"

BNC="$(scripts/fetch-builder.sh)"
LIB="$(scripts/fetch-builder.sh --lib)"
BP="$(dirname "$LIB")/bin/binate-paths"
I="$("$BP" --iface --base "$LIB" --prepend "$EXAMPLE_DIR")"
L="$("$BP" --impl --base "$LIB" --prepend "$EXAMPLE_DIR")"
RT="$("$BP" --runtime --base "$LIB")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

# Compile every demo C source to an object and collect them as --link-after-objs
# inputs (repeatable) handed to bnc's final clang link.
LINK_OBJS=""
for c in "$EXAMPLE_DIR"/csrc/*.c; do
    o="$WORK/$(basename "$c" .c).o"
    "$CC" -c -o "$o" "$c"
    LINK_OBJS="$LINK_OBJS --link-after-objs $o"
done

# build <sub> -> writes $WORK/<sub>, or returns nonzero (build log on stdout).
build() {
    # shellcheck disable=SC2086  # LINK_OBJS must word-split into flag pairs.
    "$BNC" -I "$I" -L "$L" --runtime "$RT" $LINK_OBJS \
        -o "$WORK/$1" "$EXAMPLE_DIR/cmd/$1" 2>&1
}

for sub in callrng globalrng; do
    if ! log="$(build "$sub")"; then
        echo "cinterop/tests/run.sh: FAIL — $sub failed to build"; echo "$log"; exit 1
    fi
done

fail=0
for sub in callrng globalrng; do
    want="$SCRIPT_DIR/expected/$sub.out"
    "$WORK/$sub" > "$WORK/$sub.out" 2>&1 || { echo "FAIL: $sub exited nonzero"; fail=1; continue; }
    if [ ! -f "$want" ]; then
        echo "FAIL: no fixture expected/$sub.out"; fail=1
    elif ! diff -q "$WORK/$sub.out" "$want" >/dev/null; then
        echo "FAIL: $sub != fixture"; diff "$want" "$WORK/$sub.out" | head; fail=1
    fi
done

if [ "$fail" -eq 0 ]; then
    echo "cinterop/tests/run.sh: PASS (callrng, globalrng == fixtures)"
fi
[ "$fail" -eq 0 ]
