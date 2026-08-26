# examples — TODO

## Planned examples — the standard library

The library bundled with `bnc-0.0.14` reaches well past what the examples here
show. `pkg/std` has `debug`, `errors`, `fmt`, `io`, `math` (+ `math/big`), `os`
(+ `os/process`, `os/sys`), `strconv`, `strings`, and `time`; `pkg/stdx` has
`flags`, `slices`, `cmp`, `hash`, and
`containers/{vec,hashmap,set,table,mapfn,setfn,iter}`. Only `generics` and
`minbasic` touch any of it, and neither is *about* the library.

Every entry below runs in **both modes**: the bytecode VM reaches the
libc-backed file and process layers as well as the compiler does (the "no FFI"
limit is about user `__c_call`, i.e. `cinterop`). So each gets the standard
`compiled == interpreted == fixture` harness plus unit tests, and joins the
generic sweeps with no gating.

Written roughly in the order they are worth doing:

- **`fmt` — formatted output (`pkg/std/fmt`).** The one example the series
  planned and never wrote — every other example uses `fmt` but none is *about*
  it. `Print`/`Println`/`Printf`, `Sprintf`, and `Fprintf` into a
  `strings.Builder` and `os.Stderr`; the verb, flag, width and precision grid;
  `*`/`.*` operand-supplied widths; a user type printed through `lang.Stringer`;
  and the diagnostic renderings (`%!d(...)`, `MISSING`, `EXTRA`, `NOVERB`) that
  make a bad format visible instead of silent. As of `bnc-0.0.13` every scalar
  formats (the sized ints, `uint` and `char` included) and a struct renders
  through reflection, so the example no longer has to teach around holes — check
  what `%v` of a nested struct, an array and a slice does before writing it.

- **`containers` — DONE.**

- **`files` — DONE.**

- **`errors` — DONE.**

- **`processes` — DONE.**

- **`scripting` — DONE.** The shebang names `bin/bnrun`, a launcher of the
  example's own, rather than the interpreter: `bni` has no default search path,
  and the real `-I`/`-L` are far past the kernel's ~256-byte shebang limit. As of
  `bnc-0.0.14` a *configured* environment needs no shim —
  `BINATE_PACKAGE_INTERFACE_PATH` / `BINATE_PACKAGE_IMPL_PATH` supply the paths,
  so `#!/usr/bin/env -S bni --` runs a script outright (the README shows it) —
  but this repo has to work from an unconfigured checkout, so the shim stays as
  the thing being taught. If `bni` ever defaults its search paths to its own
  installation (still open on the binate side), even that configuration goes
  away.

- **`text` — DONE.**

- **`time` — DONE.** It ships an example-local UTC calendar (`pkg/cal`), since
  the library has none. If `time` ever grows one, fold the example onto it. The
  no-clock gap is tracked on the binate side; when `time.Now()` lands, the
  file-mtime section in `cmd/dates` becomes a curiosity rather than the only way
  to see the present, and the README should say so.

- **`interfaces` — DONE.**

- **`math` — DONE.**

## Other

- **Migration off `print`/`println` — DONE.** No example calls the builtins any
  more; all output goes through `pkg/std/fmt`. A repo-wide grep is the check
  (`grep -rn '\bprintln(\|\bprint(' --include='*.bn' --include='*.bni'`), and it
  should stay empty: they are transitional debug output slated for removal from
  the language, so a new example must not reach for them.

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

  Every other example package now carries unit tests, and every example has an
  end-to-end harness. Two deliberate exceptions remain:
  - **`minbasic/pkg/host`** — the dependency-injection layer that binds the
    interpreter to real stdin/stdout/files. Unit-testing it needs fake
    descriptors; it is exercised for real by `minbasic/tests` and
    `minbasic/sessions`, which drive whole programs and REPL transcripts
    through it.
  - **`cinterop`** — compiled-only by nature (a `__c_call` cannot run under the
    VM), so it has no unit tests at all; its `tests/run.sh` builds, links, runs
    and diffs both runnables against fixtures.

- **Canary CI against the latest release.** Add a CI job that builds
  every `*/cmd/*` with `BUILDER_VERSION=latest`, separate from the pinned
  build, so a newly-published release that breaks an example is surfaced
  without reddening the main matrix. Ideal trigger: *after each binate
  release completes* (e.g. `repository_dispatch` from the release
  workflow) rather than a fixed schedule — evaluate whether that wiring
  is worth it vs. a daily cron.

- **Program-argument passing — ANSWERED (`bnc-0.0.14`).** Everything after the
  main package is the program's argv, and `--` ends *bni's* flags rather than
  introducing the program's. So the separator belongs BEFORE the package —
  `bni <flags> -- <pkg> args…` — which is what `run-interpreted.sh` does; a `--`
  placed after the package arrives as the program's first argument, which is
  what it used to do. The compiled binary takes arguments directly, so both
  modes now agree, and `scripting` is the example that reads `Args()`.

- **`cinterop` stays built by its own harness (permanent).** The C-interop
  example ships `csrc/`, so `build-all.sh` skips it — the generic bnc-only sweep
  can never compile/link a C example. Its `tests/run.sh` (run by `e2e-all.sh`)
  builds, links (`--link-after-objs`), and runs it, and CI installs `clang`
  (ubuntu-latest also has `cc`), so it exercises the example for real. This is by
  design, not a temporary gate — no action needed unless the C-interop build path
  changes. (The `lint` hygiene check is not affected: bnlint checks sources
  without linking, so it covers this example like any other.)

- **Migration off the old `bni` CLI — DONE (`bnc-0.0.14`).** `-x` is gone;
  `--` ends bni's flags and the first positional after it is the main package,
  with everything following it the program's argv. `run-interpreted.sh` moved its
  `--` to before the package (after it, the program received a literal `--` as
  its first argument), `run-tests-interpreted.sh` passes `--test <pkg>` as a
  flag VALUE, and `bin/bnrun` execs `bni <paths> -- "$@"`. `cmd/greet`'s shebang
  needed nothing: it names the shim, so the `--` lives inside `bnrun`.

  The same bump retired `binate-paths --runtime`, since a host build links no C
  runtime any more (the runtime is Binate). `_common.sh` no longer computes `RT`
  and neither `build-compiled.sh` nor `run-tests-compiled.sh` passes `--runtime`
  — it had been naming a file that no longer exists and was silently ignored.
