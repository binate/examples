# examples — TODO

- **minbasic: non-portable numeric→index conversion (NBS P168/P174/P180
  skipped).** minbasic turns an overflowed BASIC number (machine `+Inf`) into
  an integer index via `cast(int, roundf(...))` for an array subscript, an
  `ON…GOTO` index, and a `TAB` column. Casting a non-finite / out-of-range
  float to int is platform-dependent (arm64 saturates to `INT64_MAX`; x86-64
  yields `INT64_MIN`), so output differs by host ISA and the three programs are
  skipped in `minbasic/tests/SKIP`. The real fix is the toolchain making
  `cast(int,float)` well-defined (tracked in the binate repo's
  `explorations/claude-todo.md`) — a deterministic, host-independent result for
  non-finite / out-of-range inputs, which either fixes minbasic for free or lets
  it add a saturating helper at the index sites.

  Unskip path: that fix reaches examples only through a new BUILDER `bnc`
  release, since builds use the prebuilt BUILDER (`BUILDER_VERSION`, currently
  `bnc-0.0.8`) — not a binate checkout. So once the fix ships in a BUILDER
  release and `BUILDER_VERSION` is bumped past `bnc-0.0.8` here, re-run P168 /
  P174 / P180, confirm compiled == interpreted across hosts, drop them from
  `minbasic/tests/SKIP`, and re-freeze the fixtures if the now-defined behavior
  changed the output.

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

- **generics: add `vec` and `hashmap` (blocked on generic-instantiation
  bugs).** The `generics/` example ships `sort` only. A generic growable
  `Vec[T]` and a `Map[K, V]` are blocked by two toolchain limitations found
  building them, both filed in the binate repo's `explorations/claude-todo.md`:
  (1) a generic function can't take/return a generic struct instantiated with
  its own type parameter (`func Push[T any](v @Vec[T], x T)` → "cannot assign
  `Vec[T]` to `Vec[int]`"); (2) a constrained generic can't forward its type
  parameter to another constrained generic. `sort` avoids both (generic only
  over `@[]T`, single self-contained function). Add `vec` and `hashmap` once the
  fixes ship in a BUILDER release and `BUILDER_VERSION` is bumped past
  `bnc-0.0.8`.
