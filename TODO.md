# examples — TODO

- **minbasic: non-portable numeric→index conversion (NBS P168/P174/P180
  skipped).** minbasic turns an overflowed BASIC number (machine `+Inf`) into
  an integer index via `cast(int, roundf(...))` for an array subscript, an
  `ON…GOTO` index, and a `TAB` column. Casting a non-finite / out-of-range
  float to int is platform-dependent (arm64 saturates to `INT64_MAX`; x86-64
  yields `INT64_MIN`), so output differs by host ISA and the three programs are
  skipped in `minbasic/tests/SKIP`. The real fix depends on the toolchain
  decision tracked in the binate repo's `explorations/claude-todo.md` ("make
  `cast(int,float)` well-defined"): once `cast` is defined, either minbasic is
  fixed for free or it adds a deterministic saturating helper at the index
  sites — then un-skip the three programs (re-freezing fixtures if needed).

- **Unit-test coverage sweep.** The `*_test.bn` runner is in place
  (`run-tests-compiled.sh` / `run-tests-interpreted.sh` / `test-all.sh`,
  both `bnc --test` and `bni --test`, wired into CI) and `minbasic/pkg/buf`
  is covered. Progressively add unit tests for the rest of minbasic
  (lexer, parser, value/format, tab, env, …) and any future example,
  refactoring for testability where it helps.

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
