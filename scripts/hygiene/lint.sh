#!/bin/sh
# Usage: ./scripts/hygiene/lint.sh
#
# Runs the BUILDER-bundled bnlint over every example's packages and
# commands. For each example directory, the example root is prepended to
# the bundle's stdlib/runtime search roots (the same -I/-L construction
# build-compiled.sh uses, via scripts/_common.sh's set_paths), and bnlint
# is invoked on each `pkg/<name>` and `cmd/<name>` import path that has
# .bn sources.
#
# The toolchain is resolved through scripts/fetch-builder.sh, so it honors
# both the pinned BUILDER_VERSION release and a BINATE_BUNDLE override
# (e.g. a bundle built from a binate `main` checkout) automatically.
#
# Fails if any lint diagnostic is reported (or on bnlint error).
#
# Exit code: 1 if any diagnostics found (or on bnlint error), 0 otherwise.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

# Resolve the bundled bnlint and stdlib/runtime root. fetch-builder.sh
# honors BINATE_BUNDLE (a pre-built bundle) ahead of the pinned release.
BNLINT_BIN="$("$SCRIPTS_DIR/fetch-builder.sh" --tool bnlint)" || {
    echo "lint: could not resolve bnlint via fetch-builder.sh" >&2
    exit 1
}
if [ -z "$BNLINT_BIN" ] || [ ! -x "$BNLINT_BIN" ]; then
    echo "lint: bnlint not found or not executable: $BNLINT_BIN" >&2
    exit 1
fi
LIB="$("$SCRIPTS_DIR/fetch-builder.sh" --lib)" || {
    echo "lint: could not resolve the toolchain lib root" >&2
    exit 1
}

rc=0

# Lint one example. The example directory is the package search root,
# prepended ahead of the bundle's ifaces/impls roots — mirroring
# scripts/_common.sh's set_paths. Targets are the example's package
# import paths (pkg/<name>, cmd/<name>) that contain .bn sources.
for ex_dir in "$REPO_DIR"/*/; do
    ex="$(basename "$ex_dir")"
    # Only directories that look like an example (have cmd/ and/or pkg/).
    [ -d "$ex_dir/cmd" ] || [ -d "$ex_dir/pkg" ] || continue

    # An example that ships a C library (csrc/) is a C-interop example: it needs
    # a C-interop-capable toolchain (the pinned bnlint may not yet parse
    # __c_call/__c_global) and is exercised by its own harness (tests/run.sh),
    # which type-checks it by compiling. Skip it in this generic sweep — same
    # rationale as build-all.sh.
    if [ -d "$ex_dir/csrc" ]; then
        echo "lint: skipping $ex (ships csrc/, linted by its own harness)"
        continue
    fi

    root="$ex_dir"
    I="$root:$LIB:$LIB/ifaces/core:$LIB/ifaces/stdlib"
    L="$root:$LIB:$LIB/impls/core/common:$LIB/impls/core/libc:$LIB/impls/stdlib/common"

    targets=""
    # pkg/<name> import paths (subdirs of pkg/ that contain .bn files).
    if [ -d "$ex_dir/pkg" ]; then
        for d in "$ex_dir"pkg/*/; do
            [ -d "$d" ] || continue
            found=0
            for bn in "$d"*.bn; do
                [ -f "$bn" ] && found=1 && break
            done
            [ "$found" -eq 1 ] || continue
            targets="$targets pkg/$(basename "$d")"
        done
    fi
    # cmd/<name> import paths (subdirs of cmd/ that contain .bn files).
    if [ -d "$ex_dir/cmd" ]; then
        for d in "$ex_dir"cmd/*/; do
            [ -d "$d" ] || continue
            found=0
            for bn in "$d"*.bn; do
                [ -f "$bn" ] && found=1 && break
            done
            [ "$found" -eq 1 ] || continue
            targets="$targets cmd/$(basename "$d")"
        done
    fi

    # Trim leading whitespace.
    targets="$(echo "$targets" | sed -e 's/^ *//')"
    [ -n "$targets" ] || continue

    if ! "$BNLINT_BIN" -I "$I" -L "$L" $targets; then
        rc=1
    fi
done

if [ "$rc" -ne 0 ]; then
    echo ""
    echo "=== lint failed ==="
    exit 1
fi
