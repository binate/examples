# examples — TODO

- **Restore minbasic's REPL sinks to `@func`.** `minbasic/pkg/basic.bni`
  (`ReplIO.WriteOut`/`WriteErr`) and `minbasic/pkg/basic/session.bn` (`SetPoll`
  and the `poll` field) use raw `*func` as a temporary dodge: spelling them the
  contract's `@func` (as `pkg/binate/repl` does) crashes the managed
  `basicSession` destructor (`func_value_dtor on nil`, both backends). Restore
  `@func` once the binate codegen/VM defect is fixed (tracked in
  `explorations/claude-todo.md`).

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
