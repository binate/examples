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

```sh
./scripts/run-compiled.sh    minbasic/cmd/run   # -> minbasic - ECMA-55 Minimal BASIC (skeleton)
./scripts/run-interpreted.sh minbasic/cmd/run   # same, through the VM
```

> **Temporary I/O note.** minbasic's intended design injects an `io.ConsoleOut`
> into the engine, but that path miscompiles on the pinned `bnc-0.0.7`: calling
> an interface method with a 2-word slice argument drops the slice's length (both
> backends), and the VM also mishandles an injected `@func` writer. Until the fix
> ships in a release, output goes through a clearly-marked temporary static
> `pkg/host.WriteOut`. See `docs/plan.md` and the CRITICAL entries in
> `explorations/claude-todo.md`.
