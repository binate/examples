# Sourced by the build/run scripts (not run directly). The sourcing
# script must set SCRIPT_DIR (its own scripts/ directory) first.
#
# Provides REPO_DIR and two helpers:
#   parse_cmd_path <example>/cmd/<sub>  -> EXAMPLE SUB CMDDIR OUT
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
