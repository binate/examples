# examples — TODO

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

- **Activate `cinterop` once a release ships `__c_global`.** The `cinterop/`
  example (external C via `__c_call`/`__c_global`) is compiled-only and gated on
  `__c_global`, which landed on binate `main` *after* `bnc-0.0.10` (the pinned
  `BUILDER_VERSION`). For now it is withheld from the generic CI sweeps: it ships
  `csrc/`, so `build-all.sh` and the `lint` hygiene check skip it, and its
  `tests/run.sh` self-skips when the resolved `bnc` lacks `__c_global` or no C
  compiler is present. When a release includes `__c_global` and `BUILDER_VERSION`
  is bumped to it: (a) the e2e harness activates automatically — confirm it runs
  green in CI; (b) decide whether `csrc/` examples should stay harness-only or
  rejoin the generic `build-all`/`lint` sweeps; (c) ensure the CI runner provides
  a C compiler (the harness needs `cc`/`$CC` — it currently *skips* rather than
  fails when absent, which would silently drop coverage).
