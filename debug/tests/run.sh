#!/bin/sh
# tests/run.sh — the debug end-to-end harness. Runs cmd/frames in both modes and
# checks each against its own fixture, because this is the one example whose
# output is SUPPOSED to differ between them: the program reports which mode it is
# running in, which is the single thing a raw stack frame says outright.
#
# The harness also asserts that the two fixtures differ in exactly that one line.
# Everything else the program prints is derived — a call adds one frame, a skip
# removes one, a small buffer reports truncation — and those hold identically in
# both modes. Absolute depths are deliberately never printed: how many frames sit
# below main depends on the platform's startup chain when compiled and on the
# VM's own stack when interpreted.
#
# Run from anywhere (it self-locates the repo root):
#   debug/tests/run.sh
#
# Exit code: 0 if both modes match their fixtures, 1 otherwise.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXAMPLE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_DIR="$(cd "$EXAMPLE_DIR/.." && pwd)"
cd "$REPO_DIR"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM

want_c="$SCRIPT_DIR/expected/compiled.txt"
want_i="$SCRIPT_DIR/expected/interpreted.txt"
BIN="$(scripts/build-compiled.sh debug/cmd/frames)"
"$BIN" > "$WORK/compiled.out" 2>&1
scripts/run-interpreted.sh debug/cmd/frames > "$WORK/interpreted.out" 2>/dev/null

fail=0
for mode in compiled interpreted; do
    eval "want=\$want_$(echo $mode | cut -c1)"
    if [ ! -f "$want" ]; then
        echo "FAIL: $mode: no fixture $want"; fail=1
    elif ! diff -q "$WORK/$mode.out" "$want" >/dev/null; then
        echo "FAIL: $mode != fixture"; diff "$want" "$WORK/$mode.out" | head; fail=1
    fi
done

# The two fixtures must differ in exactly one line each way: the mode report.
if [ -f "$want_c" ] && [ -f "$want_i" ]; then
    changed="$(diff "$want_c" "$want_i" | grep -c '^[<>]' || true)"
    if [ "$changed" -ne 2 ]; then
        echo "FAIL: the fixtures differ in $changed lines, not 2 (only the mode should)"
        diff "$want_c" "$want_i" | head; fail=1
    fi
    if ! grep -q '^running compiled$' "$want_c" || ! grep -q '^running interpreted$' "$want_i"; then
        echo "FAIL: each fixture should name its own mode"; fail=1
    fi
fi

if [ "$fail" -eq 0 ]; then
    echo "debug/tests/run.sh: PASS (both modes match, differing only in the mode they report)"
fi
[ "$fail" -eq 0 ]
