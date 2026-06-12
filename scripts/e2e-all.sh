#!/bin/sh
# e2e-all.sh
#
# Discover and run every example's own end-to-end test harness: any
# executable run.sh living under an example directory (i.e. anywhere but
# scripts/). This is the example-level counterpart to build-all.sh (builds
# every cmd) and test-all.sh (runs every unit-test package) — an example
# whose behavior is worth checking end-to-end drops a run.sh into a
# subdirectory and it is picked up here, no central registration.
#
# minbasic ships two: tests/run.sh (the NBS Minimal BASIC program suite)
# and sessions/run.sh (the REPL session suite); each asserts
# compiled == interpreted == committed fixture across its cases.
#
# Used by CI. Exits non-zero if any harness fails.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_DIR"

# Executable run.sh outside scripts/ (the toolchain harness) and out/
# (gitignored build output). Each example harness is self-locating (it
# derives its own repo root), so invoking it by path is enough.
harnesses="$(find . -name run.sh -perm -u+x \
    -not -path './scripts/*' -not -path './out/*' -not -path './.git/*' \
    | sed 's#^\./##' | sort)"

if [ -z "$harnesses" ]; then
    echo "e2e-all: no example harnesses found (no run.sh outside scripts/)"
    exit 0
fi

found=0
failed=0
for h in $harnesses; do
    found=$((found + 1))
    echo "=== $h ==="
    if "$REPO_DIR/$h"; then
        :
    else
        echo "FAILED: $h" >&2
        failed=$((failed + 1))
    fi
done

echo "e2e-all: $found harness(es) run, $failed failure(s)"
[ "$failed" -eq 0 ]
