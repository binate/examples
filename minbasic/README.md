# minbasic

An embeddable interpreter for **ECMA-55 "Minimal BASIC"** — a "serious" Binate
example that demonstrates an embeddable REPL (same contract shape as
`pkg/binate/repl`), dependency-injected I/O (the interpreter core reaches no
low-level I/O directly), and idiomatic Binate (tagged-union ASTs, managed/raw
slices, refcounting, errors-as-values).

**Status: work in progress** — see [`docs/plan.md`](docs/plan.md) for the
architecture, milestones, and open decisions. Run instructions land with the
first runnable milestone (`run prog.bas`).
