#!/bin/sh
# builder-gate.sh <example-dir>
#
# Decide whether an example must be SKIPPED because the resolved Binate toolchain
# is too old to compile it — a TEMPORARY gate for examples that use a language
# feature which has landed on binate `main` but is not in the pinned
# BUILDER_VERSION release yet.
#
# Mechanism: if <example-dir>/.builder-probe exists, it is a minimal program
# using the one feature the example needs. This script compiles it with the
# resolved bnc (scripts/fetch-builder.sh, honoring BINATE_BUNDLE). The probe
# either compiles (feature present) or not (feature absent).
#
# Exit status:
#   0  gated   — the probe exists AND fails to compile (skip the example)
#   1  ungated — no probe, or the probe compiles (build/test/lint the example)
#
# This AUTO-HEALS: once the pinned toolchain (or a BINATE_BUNDLE) compiles the
# probe, the example is no longer gated and rejoins the sweeps with no edit. It
# differs from the permanent `csrc/` skip (a C-interop example can NEVER be built
# by the generic bnc-only sweep); a feature gate is temporary and self-clearing.
#
# Callers treat any non-zero as "not gated", so a resolver/setup failure here
# does not silently drop an example — it just runs normally (and fails loudly if
# genuinely broken).
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

[ $# -eq 1 ] || { echo "usage: $0 <example-dir>" >&2; exit 2; }
EX_DIR="$1"
PROBE="$EX_DIR/.builder-probe"

# No probe -> not a gated example.
[ -f "$PROBE" ] || exit 1

# Resolve the toolchain; a failure to resolve is "not gated" (exit 1), so the
# sweep proceeds rather than silently skipping.
BNC="$("$SCRIPT_DIR/fetch-builder.sh")" || exit 1
LIB="$("$SCRIPT_DIR/fetch-builder.sh" --lib)" || exit 1
BP="$(dirname "$LIB")/bin/binate-paths"
I="$("$BP" --iface --base "$LIB")" || exit 1
L="$("$BP" --impl --base "$LIB")" || exit 1
RT="$("$BP" --runtime --base "$LIB")" || exit 1

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT INT TERM
# The probe is a self-contained `package "main"` with no example-local imports,
# so the bundle's base search paths suffice. bnc wants a directory of sources.
mkdir -p "$WORK/probe"
cp "$PROBE" "$WORK/probe/main.bn"

if "$BNC" -I "$I" -L "$L" --runtime "$RT" -o "$WORK/probe.bin" "$WORK/probe" >/dev/null 2>&1; then
    exit 1   # probe compiles -> feature present -> not gated
fi
exit 0       # probe fails -> feature absent -> gated (skip)
