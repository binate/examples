# Sourced by the build/run scripts (not run directly). The sourcing
# script must set SCRIPT_DIR (its own scripts/ directory) first.
#
# Provides REPO_DIR and three helpers:
#   parse_cmd_path <example>/cmd/<sub>  -> EXAMPLE SUB CMDDIR OUT
#   parse_pkg_path <example>/<pkg-path> -> EXAMPLE PKG PKGDIR
#   set_paths      <example> <lib>      -> I L RT  (search paths rooted at the example)

REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

parse_cmd_path() {
    _cmd="${1%/}"
    case "$_cmd" in
        */cmd/*) ;;
        *) echo "expected an <example>/cmd/<subexample> path, got: $1" >&2; exit 2 ;;
    esac
    EXAMPLE="${_cmd%%/*}"
    SUB="$(basename "$_cmd")"
    CMDDIR="$REPO_DIR/$_cmd"
    OUT="$REPO_DIR/out/$EXAMPLE/$SUB"
    [ -d "$CMDDIR" ] || { echo "no such example directory: $_cmd" >&2; exit 2; }
}

# Split a test-package path (e.g. minbasic/pkg/buf) into the example root and the
# import path that `bnc --test` / `bni --test` resolve. The example directory is
# the package search root (prepended by set_paths), so EXAMPLE is the first path
# component and PKG is the remainder — the import path as written in source
# (`import "pkg/buf"`). A `cmd/<sub>` package works too (PKG = cmd/<sub>).
parse_pkg_path() {
    _pkg="${1%/}"
    case "$_pkg" in
        */*) ;;
        *) echo "expected an <example>/<pkg-path> path, got: $1" >&2; exit 2 ;;
    esac
    EXAMPLE="${_pkg%%/*}"
    PKG="${_pkg#*/}"
    PKGDIR="$REPO_DIR/$_pkg"
    [ -d "$PKGDIR" ] || { echo "no such package directory: $_pkg" >&2; exit 2; }
}

# Each example is its own package search root, prepended ahead of the
# bundle's stdlib/runtime roots (the bundle layout per BUNDLE-HOWTO.md).
set_paths() {
    _root="$REPO_DIR/$1"
    _lib="$2"
    # binate-paths (shipped in the bundle's bin/, the sibling of lib/) is the
    # single source of truth for the package search-path formula documented in
    # BUNDLE-HOWTO.md.  --prepend puts the example dir ahead of the bundle's
    # stdlib/runtime roots; --base points it at the bundle's lib/.
    _bp="$(dirname "$_lib")/bin/binate-paths"
    I="$("$_bp" --iface --base "$_lib" --prepend "$_root")"
    L="$("$_bp" --impl --base "$_lib" --prepend "$_root")"
    RT="$("$_bp" --runtime --base "$_lib")"
}
