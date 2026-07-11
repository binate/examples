#!/bin/sh
# test-all.sh [compiled|interpreted|both]
#
# Discover every example package carrying unit tests (*_test.bn at any
# depth under an example) and run them. Used by CI. The mode selects the
# backend(s):
#
#   compiled      bnc --test (compile + run a native test binary)
#   interpreted   bni --test (bytecode VM, no native build)
#   both          run each package under both (default)
#
# Exits non-zero if any package's tests fail to build or fail.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

mode="${1:-both}"
case "$mode" in
    compiled|interpreted|both) ;;
    *) echo "usage: $0 [compiled|interpreted|both]" >&2; exit 2 ;;
esac

# Unique <example>/<pkg-path> dirs holding *_test.bn (out/ is gitignored
# build output; .git holds no source).
pkgs="$(find . -name '*_test.bn' -not -path './out/*' -not -path './.git/*' \
    | sed 's#/[^/]*$##; s#^\./##' | sort -u)"

if [ -z "$pkgs" ]; then
    echo "test-all: no test packages found (no *_test.bn)"
    exit 0
fi

found=0
failed=0
skipped=0
for pkg in $pkgs; do
    # An example gated on a language feature the resolved bnc predates (a
    # temporary, self-clearing gate — e.g. variadics until the next release).
    example="${pkg%%/*}"
    if "$SCRIPT_DIR/builder-gate.sh" "$example"; then
        echo "=== $pkg (skipped: $example needs a newer builder) ==="
        skipped=$((skipped + 1))
        continue
    fi
    found=$((found + 1))
    echo "=== $pkg ==="
    if [ "$mode" != interpreted ]; then
        if ! "$SCRIPT_DIR/run-tests-compiled.sh" "$pkg"; then
            echo "FAILED (compiled): $pkg" >&2
            failed=$((failed + 1))
        fi
    fi
    if [ "$mode" != compiled ]; then
        if ! "$SCRIPT_DIR/run-tests-interpreted.sh" "$pkg"; then
            echo "FAILED (interpreted): $pkg" >&2
            failed=$((failed + 1))
        fi
    fi
done

echo "test-all: $found package(s) tested, $failed failure(s), $skipped skipped (builder-gated)"
[ "$failed" -eq 0 ]
