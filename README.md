# Binate examples

Example programs for the [Binate](https://github.com/binate) programming
language and toolchain.

## Layout

Each example is a self-contained mini-project that doubles as its own package
search root:

```
<example>/
  cmd/<subexample>/    one runnable program per directory (package "main")
  pkg/...              (optional) packages private to the example
```

A runnable example is identified by its `cmd` path, e.g. `hello/cmd/hello`.
Grouping several runnables under one `<example>` lets them share that example's
`pkg/...`; an example's own packages resolve because the example directory is
prepended to the toolchain's `-I`/`-L` search paths.

## Toolchain

Builds use a released Binate bundle (`bnc`, `bni`, plus the standard library and
C runtime) — no Binate source checkout required, just `clang` on `PATH` for
linking compiled output. The version is pinned in `BUILDER_VERSION` and
fetched/cached on demand by `scripts/fetch-builder.sh`:

```sh
BUILDER_VERSION=latest ./scripts/build-compiled.sh hello/cmd/hello   # override the pin
```

`latest` resolves the newest published release; bundles are sha256-verified and
cached under `~/.cache/binate/builders/`.

To build against a toolchain you built yourself — e.g. a binate `main` checkout,
ahead of the latest release — point at its bundle directory directly:

```sh
BINATE_BUNDLE=/path/to/bundle ./scripts/build-compiled.sh hello/cmd/hello
```

`BINATE_BUNDLE` skips the versioned download entirely; the directory just needs
the bundle layout (`bin/`, `lib/`).

## Scripts

```
scripts/build-compiled.sh   <example>/cmd/<sub>             compile to out/
scripts/run-compiled.sh     <example>/cmd/<sub> [args...]   compile + run native
scripts/run-interpreted.sh  <example>/cmd/<sub> [args...]   run via the bytecode VM (bni)
scripts/build-all.sh                                        compile every */cmd/* (CI)
```

Compiled binaries land under `out/<example>/<sub>` (gitignored).

```sh
./scripts/run-compiled.sh    hello/cmd/hello     # -> Hello from Binate!
./scripts/run-interpreted.sh hello/cmd/hello     # same, through the VM
```

## Examples

Each example directory has its own `README.md` with run commands and expected
output.

- [`hello`](hello/) — minimal "hello world".
- [`numbers`](numbers/) — an example-local package (`pkg/seq`) shared by two
  runnables; shows the search-root + multi-runnable layout.
- [`minbasic`](minbasic/) — a "serious" example: an embeddable **ECMA-55 Minimal
  BASIC** interpreter. Two runnables (`cmd/run`, a batch program runner;
  `cmd/basic`, a REPL) over example-local packages (`pkg/basic`, `pkg/buf`,
  `pkg/host`) with `.bni` interface files and dependency-injected I/O. It carries
  its own program/REPL test suites (`minbasic/tests/`, `minbasic/sessions/`).

See [`TODO.md`](TODO.md) for planned work (test scripts, a canary CI run against
the latest release).
