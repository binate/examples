# minbasic

An embeddable interpreter for **ECMA-55 "Minimal BASIC"** — a "serious" Binate
example that demonstrates an embeddable REPL (same contract shape as
`pkg/binate/repl`), dependency-injected I/O (the interpreter core reaches no
low-level I/O directly), and idiomatic Binate (tagged-union ASTs, managed/raw
slices, refcounting, errors-as-values).

**Status: work in progress** (M0 skeleton). See [`docs/plan.md`](docs/plan.md)
for the architecture, milestones, and open decisions, and
[`docs/ecma55-notes.md`](docs/ecma55-notes.md) for the language digest.

## Run (M0 skeleton)

minbasic injects an `io.ConsoleOut` into the engine — the core never touches an
fd. That needs a toolchain with the interface-vtable fix, which is in binate
`main` but not in the pinned `bnc-0.0.7` release yet, so build against a
`main`-built bundle (`BINATE_BUNDLE`, see the repo README):

```sh
BINATE_BUNDLE=/path/to/main/bundle ./scripts/run-compiled.sh    minbasic/cmd/run
BINATE_BUNDLE=/path/to/main/bundle ./scripts/run-interpreted.sh minbasic/cmd/run
# -> minbasic - ECMA-55 Minimal BASIC (skeleton)
```

> **Toolchain note.** On the pinned `bnc-0.0.7` the example *compiles* (CI stays
> green) but produces wrong output at runtime: an interface method taking a
> 2-word slice argument miscompiles in that release. It's fixed in `main`, so run
> against a `main` bundle until the pin is bumped to a release carrying the fix.
