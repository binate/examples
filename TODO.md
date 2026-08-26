# examples — TODO

## Examples still to write

The library bundled with `bnc-0.0.14` reaches past what the examples cover.
One package has no example of its own:

- **`debug` — (`pkg/std/debug`).** Read the `.bni` first; scope the example to
  what it actually offers.

## Open work

- **`minbasic/pkg/host` has no unit tests.** The dependency-injection layer that
  binds the interpreter to real stdin/stdout/files; testing it needs fake
  descriptors. It is exercised end-to-end by `minbasic/tests` and
  `minbasic/sessions`, which drive whole programs and REPL transcripts through
  it, so this is a coverage gap rather than a hole.

- **Canary CI against the latest release.** Add a CI job that builds every
  `*/cmd/*` with `BUILDER_VERSION=latest`, separate from the pinned build, so a
  newly-published release that breaks an example is surfaced without reddening
  the main matrix. Ideal trigger: *after each binate release completes* (e.g.
  `repository_dispatch` from the release workflow) rather than a fixed schedule
  — evaluate whether that wiring is worth it vs. a daily cron.

## Waiting on the toolchain

- **`time` gets a clock.** `pkg/std/time` has no `Now()` and no `Sleep`, which
  is why `time/cmd/dates` learns today's date by writing a file and reading its
  modification time back. When a clock lands, that section becomes a curiosity
  rather than the only way, and the example and its README should say so.

- **`bni` gets a default search path.** It currently resolves no packages of its
  own, so `scripting` ships `bin/bnrun` to supply `-I`/`-L`. A configured
  environment already needs no shim (`BINATE_PACKAGE_INTERFACE_PATH` /
  `BINATE_PACKAGE_IMPL_PATH`, `bnc-0.0.14`); a default root would remove even
  that, leaving `#!/usr/bin/env -S bni --` complete on its own.
