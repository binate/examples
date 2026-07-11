# Binate examples

[![CI](https://github.com/binate/examples/actions/workflows/ci.yml/badge.svg)](https://github.com/binate/examples/actions/workflows/ci.yml)

Example programs for the [Binate](https://github.com/binate) programming
language and toolchain.

## Layout

Each example is a self-contained mini-project that doubles as its own package
search root:

```
<example>/
  cmd/<subexample>/    one runnable program per directory (package "main")
  pkg/...              (optional) packages private to the example
  csrc/                (optional) C sources the example links against (C interop)
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

Some examples use a language feature newer than the pinned release (already on
binate `main`). They are **builder-gated**: `scripts/builder-gate.sh` compiles a
tiny `.builder-probe` in the example with the resolved toolchain, and the CI
sweeps (`build-all`, `test-all`, `lint`) and the example's own harness skip it
while that probe fails. Point `BINATE_BUNDLE` at a `main` build to run them now;
once `BUILDER_VERSION` catches up, the probe compiles and they rejoin CI with no
edit. (`cinterop` is gated differently — it ships `csrc/` and is *permanently*
built by its own harness, since the generic bnc-only sweep can never link its C.)

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

## Tests

Examples can carry **unit tests** — `*_test.bn` files next to the code, with
`func TestXxx() testing.TestResult` functions (return `""` to pass, a message to
fail; `import "pkg/builtins/testing"`). They run through the toolchain's own test
support, in either mode:

```
scripts/run-tests-compiled.sh    <example>/<pkg>   bnc --test (compile + run)
scripts/run-tests-interpreted.sh <example>/<pkg>   bni --test (bytecode VM)
scripts/test-all.sh [compiled|interpreted|both]    run every *_test.bn package (CI)
```

The package argument is `<example>/<import-path>` (e.g. `minbasic/pkg/buf`).

An example can also carry **end-to-end suites** — any executable `run.sh` under
the example directory (e.g. `minbasic/tests/run.sh`, `minbasic/sessions/run.sh`).
`scripts/e2e-all.sh` discovers and runs them all (also in CI).

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
- [`mandelbrot`](mandelbrot/) — renders the **Mandelbrot set** as ASCII art,
  split into an abstract escape-time calculator (`pkg/mandel`) and a separate
  ASCII renderer (`pkg/ascii`). The calculator streams each sample's escape count
  to a caller-supplied plot closure; the renderer's closure captures its grid.
  Carries unit tests for both packages and a pinned end-to-end picture fixture.
- [`generics`](generics/) — Binate **generics**: a growable `Vec`, an
  open-addressing `Map`, and a `Sort`, bounded by the `lang` constraints
  (`Orderable`/`Hashable`) — constraint-method dispatch, monomorphized,
  bodies-in-`.bni`, with both primitives and user types satisfying the bounds.
  `cmd/demo` composes the three (collect → sort → tally).
- [`cinterop`](cinterop/) — calling **external C library code** from Binate via
  the `__c_call` (call a C function) and `__c_global` (address a C global)
  intrinsics, against a small demo C library (`csrc/rng.c`, a deterministic
  PRNG) linked in with bnc's `--link-after-objs`. Compiled-mode only (the VM
  does no FFI), and it needs a C compiler; its harness self-skips until the
  pinned toolchain includes `__c_global` (see the example's README).
- [`variadics`](variadics/) — **variadic functions** (`func f(xs ...T)`) and the
  **spread** operator (`slice...`): an aggregation library (`pkg/agg` — `Sum`,
  `Max`, `Fold`, a generic `Count[T]`) showing individual-argument packing (zero
  heap), spread, a fixed parameter before the variadic, variadic function values,
  and generic variadics. Runs in both modes with unit tests. Variadics landed
  after `bnc-0.0.10`, so it is **builder-gated** — skipped by the CI sweeps and
  its harness until the pinned toolchain supports it (see the example's README).

See [`TODO.md`](TODO.md) for planned work (a canary CI run against the latest
release, the unit-test coverage sweep).
