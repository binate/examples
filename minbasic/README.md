# minbasic

An embeddable interpreter for **ECMA-55 "Minimal BASIC"** — a "serious" Binate
example that demonstrates an embeddable REPL (same contract shape as
`pkg/binate/repl`), dependency-injected I/O (the interpreter core reaches no
low-level I/O directly), and idiomatic Binate (tagged-union ASTs, managed/raw
slices, refcounting, errors-as-values).

It implements the whole standard — `LET`/`PRINT`/`GOTO`/`IF`/`FOR`/`GOSUB`/
`ON…GOTO`/`READ`/`DATA`/`DIM` arrays/`DEF FN`/`INPUT`, the supplied numeric
functions, and ECMA-55 PRINT formatting — across two runnables: `cmd/run` (a
batch runner, `run prog.bas`) and `cmd/basic` (an interactive REPL). The
interpreter core (`pkg/basic`) depends only on the `pkg/basic/io` interfaces;
`pkg/host` is the one package that reaches the OS (via `pkg/std/os`). See
[`docs/ecma55-notes.md`](ecma55-notes.md) for the language digest.

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
the example carries its own end-to-end suites: `tests/run.sh` runs a vendored
**NBS conformance** set and `sessions/run.sh` the REPL sessions, each asserting
compiled == interpreted == committed fixture in both modes.

See [`examples/`](examples/) for sample BASIC programs to run — `hello.bas` and,
meta as it is, an ASCII `mandelbrot.bas` written in Minimal BASIC.
