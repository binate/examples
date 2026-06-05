# examples — TODO

- **Tests.** Support `*_test.bn` in examples (not required per example).
  Decide whether to run tests via `bni --test`, `bnc --test`, or both,
  and add the scripts — strawman: `build-tests-compiled.sh`,
  `run-tests-compiled.sh`, `run-tests-interpreted.sh`. Settle once we
  have an example that actually carries tests.

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

- **GitHub Actions Node 20 deprecation.** `.github/workflows/build.yml` uses
  `actions/checkout@v4` and `actions/cache@v4`, which run on Node 20. GitHub
  forces Node 24 on 2026-06-16 and removes Node 20 on 2026-09-16 — bump to the
  Node 24-compatible action versions before then (the build is green today).
