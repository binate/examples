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
for dir in */cmd/*/; do
    [ -d "$dir" ] || continue          # no matches -> glob stays literal
    cmd="${dir%/}"
    found=$((found + 1))
    echo "=== $cmd ==="
    if "$SCRIPT_DIR/build-compiled.sh" "$cmd"; then
        :
    else
        echo "FAILED: $cmd" >&2
        failed=$((failed + 1))
    fi
done

if [ "$found" -eq 0 ]; then
    echo "build-all: no runnable examples found (looked for */cmd/*/)" >&2
    exit 1
fi
echo "build-all: $((found - failed))/$found example(s) built"
[ "$failed" -eq 0 ]
