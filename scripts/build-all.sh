#!/bin/sh
# build-all.sh
#
# Compile every runnable example (every */cmd/*). Used by CI. Exits
# non-zero if any example fails to build.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

found=0
failed=0
skipped=0
for dir in */cmd/*/; do
    [ -d "$dir" ] || continue          # no matches -> glob stays literal
    cmd="${dir%/}"
    # An example that ships a C library (csrc/) is compiled AND linked against
    # that C object by its own e2e harness (it needs a C compiler and bnc's
    # --link-after-objs), not by this generic bnc-only sweep — which would fail
    # to resolve the C symbols.  Skip the whole example; its harness covers it.
    example="${cmd%%/*}"
    if [ -d "$example/csrc" ]; then
        echo "=== $cmd (skipped: $example ships csrc/, built by its own harness) ==="
        skipped=$((skipped + 1))
        continue
    fi
    # An example gated on a language feature the resolved bnc predates (a
    # temporary, self-clearing gate — e.g. variadics until the next release).
    if "$SCRIPT_DIR/builder-gate.sh" "$example"; then
        echo "=== $cmd (skipped: $example needs a newer builder — see $example/README.md) ==="
        skipped=$((skipped + 1))
        continue
    fi
    found=$((found + 1))
    echo "=== $cmd ==="
    if "$SCRIPT_DIR/build-compiled.sh" "$cmd"; then
        :
    else
        echo "FAILED: $cmd" >&2
        failed=$((failed + 1))
    fi
done

if [ "$found" -eq 0 ] && [ "$skipped" -eq 0 ]; then
    echo "build-all: no runnable examples found (looked for */cmd/*/)" >&2
    exit 1
fi
echo "build-all: $((found - failed))/$found example(s) built, $skipped skipped (csrc/ or builder-gated)"
[ "$failed" -eq 0 ]
