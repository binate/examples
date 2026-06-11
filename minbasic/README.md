# minbasic

An embeddable interpreter for **ECMA-55 "Minimal BASIC"** — a "serious" Binate
example that demonstrates an embeddable REPL (same contract shape as
`pkg/binate/repl`), dependency-injected I/O (the interpreter core reaches no
low-level I/O directly), and idiomatic Binate (tagged-union ASTs, managed/raw
slices, refcounting, errors-as-values).

**Status: work in progress** (M0 skeleton). See [`docs/plan.md`](docs/plan.md)
for the architecture, milestones, and open decisions, and
[`docs/ecma55-notes.md`](docs/ecma55-notes.md) for the language digest.

## Run

minbasic injects an `io.ConsoleOut` into the engine — the core never touches an
fd. Build it against the pinned release bundle (`BUILDER_VERSION`), then run a
BASIC program through it:

```sh
./scripts/build-compiled.sh minbasic/cmd/run
out/minbasic/run minbasic/programs/integers.bas
#  1  2
#  1              2
#  10  20  30
#  42
# -5
```

It also runs interpreted (`./scripts/run-interpreted.sh minbasic/cmd/run`), and
`minbasic/tests/run.sh` checks every program in `programs/` against an expected
fixture (compiled == interpreted == fixture).

> **Toolchain note.** The interface-vtable fix that minbasic's
> dependency-injected `io.ConsoleOut` relies on (an interface method taking a
> 2-word slice argument was miscompiled in `bnc-0.0.7`) shipped in `bnc-0.0.8`,
> so the example now runs correctly against the pinned release — no `main`-built
> `BINATE_BUNDLE` required.
