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

- **`containers` — DONE.** One thing to revisit: `countWords` sits in
  `cmd/wordcount` instead of `pkg/tally`, because the pinned `bnc-0.0.12` rejects
  a `.bni` that names a generic instantiated on a type its own package `impl`s —
  `func Counts(…) @hashmap.Map[Word, int]` fails with "type argument Word does
  not satisfy constraint Hashable" though the `impl` is in the same file. **Fixed
  upstream** (binate `ff505c92`); once `BUILDER_VERSION` names a release carrying
  it, move `countWords` into `pkg/tally` as `Counts` (with a unit test — the
  package's own `.bn` tests can already build such a map) and drop the
  explanations from `containers/README.md` and `pkg/tally.bni`.

- **`files` — DONE.**

- **`errors` — DONE, but compiled-only and outside the default sweeps.** `bni`
  SIGSEGVs on `errors.Is` over a user-defined `errors.Error`, which the example's
  `ParseError` is — a tracked MAJOR, reproduced on both the pinned `bnc-0.0.12`
  and a `main` build. When a toolchain carrying the fix is pinned: delete
  `errors/.skip-default-sweeps`, restore the interpreted leg in
  `errors/tests/run.sh` (it becomes the usual two-way diff), and drop the note
  from the example's README and from the entry in the top-level README.

- **`processes` — DONE.**

- **`scripting` — `#!` shebang scripts and `bni -x`.** One `.bn` file that runs
  three ways: `bni -x script.bn args…`, directly as `./script.bn args…` via the
  kernel, and compiled by `bnc` (the lexer skips the `#!` line, so the same
  source is a valid program). `os.Args()` differs between them — under `bni -x`
  element 0 is the script path; a compiled binary gets a placeholder. Note the
  deployment constraint: this bni resolves no stdlib of its own, so the shebang
  must carry `-I`/`-L`, and the real bundle paths blow past the kernel's ~256-byte
  shebang limit — the harness stamps a runnable script (short symlinked search
  paths) the way binate's own `e2e/shebang-exec.sh` does.

- **`text` — DONE.**

- **`time` — DONE.** It ships an example-local UTC calendar (`pkg/cal`), since
  the library has none. If `time` ever grows one, fold the example onto it. The
  no-clock gap is tracked on the binate side; when `time.Now()` lands, the
  file-mtime section in `cmd/dates` becomes a curiosity rather than the only way
  to see the present, and the README should say so.

- **`interfaces` — nominal interfaces and type recovery.** `impl T : I` being
  required (a matching method set is never enough), interface values as `*I` /
  `@I`, construction borrowing, and the assertion forms with their mandatory
  recovery kind — `v.(@T)` / `v.(*T)` / `v.(T)`, comma-ok vs. the aborting bare
  form — plus type switches and `present`/`same`. `minbasic` uses interfaces
  for its injected I/O, but nothing here shows assertions or type switches.

- **`math` — DONE, with one thing to undo.** The example builds its negative
  zero with `math.Copysign(0.0, -1.0)` instead of writing the `-0.0` literal,
  because the bytecode VM computes `-x` as `0.0 - x` and so loses the sign of a
  zero — the literal makes the program disagree with itself between compiled and
  interpreted mode. (Copysign is the portable spelling anyway, which is why this
  costs the example nothing.) Tracked as a MAJOR VM bug on the binate side;
  once a toolchain carrying the fix is pinned, restore the `-0.0` literal in
  `math/cmd/floats/main.bn` and `math/pkg/fp/fp_test.bn` — it is the more direct
  way to show a negative zero — and drop the explanations from both files and
  from `math/README.md`.

## Other

- **Migration off `print`/`println` — DONE.** No example calls the builtins any
  more; all output goes through `pkg/stdx/fmt`. A repo-wide grep is the check
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
