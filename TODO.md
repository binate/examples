# examples — TODO

## Planned examples — the standard library

The library bundled with `bnc-0.0.12` reaches well past what the examples here
show. `pkg/std` has `errors`, `io`, `math` (+ `math/big`), `os` (+ `os/process`,
`os/sys`), `strconv`, `strings`, and `time`; `pkg/stdx` has `fmt`, `slices`,
`cmp`, `hash`, and `containers/{vec,hashmap,set,table,mapfn,setfn,iter}`. Only
`generics` and `minbasic` touch any of it, and neither is *about* the library.

Every entry below runs in **both modes**: the bytecode VM reaches the
libc-backed file and process layers as well as the compiler does (the "no FFI"
limit is about user `__c_call`, i.e. `cinterop`). So each gets the standard
`compiled == interpreted == fixture` harness plus unit tests, and joins the
generic sweeps with no gating.

Written roughly in the order they are worth doing:

- **`fmt` — formatted output (`pkg/stdx/fmt`).** `Print`/`Println`/`Printf`,
  `Sprintf`, and `Fprintf` into a `strings.Builder` and `os.Stderr`; the verb,
  flag, width and precision grid; `*`/`.*` operand-supplied widths; a user type
  printed through `lang.Stringer`; and the diagnostic renderings (`%!d(...)`,
  `MISSING`, `EXTRA`, `NOVERB`) that make a bad format visible instead of
  silent. Must document what fmt actually recognizes: `int`, `int64`, `uint64`,
  `bool`, `float32/64`, the char-slice string spellings, and `lang.Stringer`.
  A `uint`, a sized int (`int8/16/32`, `uint8/16/32`), or a `char` renders as
  `%!d(?=42)` and needs `cast(int, x)`; a struct or slice operand renders
  `%!?(unknown)` (struct reflection is a later layer).

- **`containers` — the stdlib containers (`pkg/stdx/containers`).** `Vec[T]`,
  `Map[K, V]`, and `Set[T]` over both a primitive key and a user type that
  implements `lang.Hashable` (`Hash` + `Compare`, value receivers — the
  constraint's `Self` is the value type); the shared cursor convention
  (`Iter()` → `Cursor`, `Next() (T, bool)`) and the boxed `iter.Iterator[T]` /
  `iter.Iterable[T]` protocol that lets non-generic code walk any container;
  and `stdx/slices.Append`. Distinct from `generics`, which *writes* generic
  containers — this one *uses* the library's.

- **`files` — files and byte streams (`pkg/std/os`, `pkg/std/io`).**
  `Create`/`Open`/`Write`/`Read` with the `io.EOF` loop (`io.IsEOF`), `Seek`,
  `ReadAt`, `Stat` (size, `FileMode`, `ModTime`), `ReadDir`, `Mkdir`/`MkdirAll`,
  `Rename`, `Remove`, and `errors.Is(err, errors.NotFound)`. Works in a temp
  directory and prints derived facts, so the fixture stays deterministic.

- **`errors` — errors as values (`pkg/std/errors`).** `present(err)` rather
  than a nil test; `New`/`Wrap` and walking a cause chain with `Unwrap`;
  `errors.Is` finding a sentinel through wrapping; `Rooted` and the standard
  base hierarchy (`NotFound ⊂ ConditionsUnmet`, …) that stdlib errors classify
  under; and a user type implementing the `Error` interface.

- **`processes` — running a child program (`pkg/std/os/process`).**
  `RunArgs`/`RunArgsPath`/`LookPath`, `Options` (`Args`, `Env`, `ReplaceEnv`,
  `SearchPath`), and the `ExitStatus` shape that makes a non-zero exit *not* an
  error: `Exited`/`Code`/`Signaled`/`Signal`/`Success`, including a
  signal-killed child. Plus `os.Env()`/`os.Args()`.

- **`scripting` — `#!` shebang scripts and `bni -x`.** One `.bn` file that runs
  three ways: `bni -x script.bn args…`, directly as `./script.bn args…` via the
  kernel, and compiled by `bnc` (the lexer skips the `#!` line, so the same
  source is a valid program). `os.Args()` differs between them — under `bni -x`
  element 0 is the script path; a compiled binary gets a placeholder. Note the
  deployment constraint: this bni resolves no stdlib of its own, so the shebang
  must carry `-I`/`-L`, and the real bundle paths blow past the kernel's ~256-byte
  shebang limit — the harness stamps a runnable script (short symlinked search
  paths) the way binate's own `e2e/shebang-exec.sh` does.

- **`text` — building and parsing text (`pkg/std/strings`, `pkg/std/strconv`).**
  `strings.Builder` as an `io.Writer` (`Write`/`WriteByte`/`Grow`/`Reset`, and
  `String()` sharing the backing without a copy); `strconv`'s `Parse*` family
  with its error reporting, the allocating `Format*`/`Itoa`, and the
  no-allocation `Append*` family with its negative "space needed" overflow
  contract.

- **`time` — points and deltas (`pkg/std/time`).** `FromUnix`/`ToUnix`,
  ordering (`Before`/`After`/`Equal`), `Sub` → `Delta`, and a file's `ModTime`
  from `os.Stat` as the one Point that comes from the outside world. Note there
  is **no clock**: the library has no `Now()` and no `Sleep`, so an example can
  only do arithmetic on constructed Points and on file times.

- **`interfaces` — nominal interfaces and type recovery.** `impl T : I` being
  required (a matching method set is never enough), interface values as `*I` /
  `@I`, construction borrowing, and the assertion forms with their mandatory
  recovery kind — `v.(@T)` / `v.(*T)` / `v.(T)`, comma-ok vs. the aborting bare
  form — plus type switches and `present`/`same`. `minbasic` uses interfaces
  for its injected I/O, but nothing here shows assertions or type switches.

- **`math` — floating point (`pkg/std/math`, `pkg/std/math/big`).** The IEEE
  surface (`NaN`/`Inf` and their tests, `Copysign`, `Frexp`/`Ldexp`, rounding
  modes) alongside Binate's defined-everything arithmetic (saturating float→int
  `cast`, `x != x` for NaN), and `big.Nat` arbitrary-precision integers.

## Other

- **Unit-test coverage sweep (largely complete).** minbasic's `pkg/buf` and
  the whole `pkg/basic` core are unit-tested (~166 tests, green under both
  `bnc --test` and `bni --test`, run in CI): lexer/token, parser
  (expression/statement/relational), evaluator and executor (via a
  `captureOut`/`scriptIn` runtime harness in `harness_test.bn`), the ECMA-55
  number formatter, variable/array storage, the supplied functions + DEF FN,
  READ/DATA, INPUT, the program store + line map, the embeddable REPL session,
  and the runtime/load error paths. What remains is marginal and largely
  covered indirectly (the `setup`/`usesarray` load helpers, the DIM/DEF parser
  internals). Add unit tests for any new example as it lands.

- **Canary CI against the latest release.** Add a CI job that builds
  every `*/cmd/*` with `BUILDER_VERSION=latest`, separate from the pinned
  build, so a newly-published release that breaks an example is surfaced
  without reddening the main matrix. Ideal trigger: *after each binate
  release completes* (e.g. `repository_dispatch` from the release
  workflow) rather than a fixed schedule — evaluate whether that wiring
  is worth it vs. a daily cron.

- **Program-argument passing.** Confirm how arguments reach an example
  under `bni` (whether a `--` separator is needed) vs. the compiled
  binary, once we have an example that reads `Args()`. The run scripts
  currently forward extra args as-is.

- **`cinterop` stays built by its own harness (permanent).** The C-interop
  example ships `csrc/`, so `build-all.sh` skips it — the generic bnc-only sweep
  can never compile/link a C example. Its `tests/run.sh` (run by `e2e-all.sh`)
  builds, links (`--link-after-objs`), and runs it, and CI installs `clang`
  (ubuntu-latest also has `cc`), so it exercises the example for real. This is by
  design, not a temporary gate — no action needed unless the C-interop build path
  changes. (The `lint` hygiene check is not affected: bnlint checks sources
  without linking, so it covers this example like any other.)
