# minbasic NBS conformance / regression harness

This directory runs minbasic against the public-domain **NBS Minimal BASIC test
programs** (NBS SP 500-70; see `PROVENANCE.md`). It is a **regression oracle**:
the committed fixtures in `expected/` are minbasic's own frozen output, reviewed
and (where comparable) cross-checked against the bas55 reference. It is *not* an
independent oracle.

## Layout

- `nbs/` — the vendored `P*.BAS` programs (public domain), the runnable-now subset.
- `expected/` — `<name>.out`, the frozen expected output (minbasic's own bytes).
- `input/` — `<name>.in`, the canned stdin reply stream for programs that read
  `INPUT` (authored to drive a correct, complete run; absent for the common
  no-`INPUT` case, which runs on `/dev/null`).
- `run.sh` — the runner; `PROVENANCE.md` — licensing/credit.

## Running

From the examples repo root, with `BINATE_BUNDLE` set:

```sh
BINATE_BUNDLE=/path/to/main/bundle minbasic/tests/run.sh
```

For every program in `nbs/`, `run.sh` executes it **compiled** and
**interpreted** and asserts `compiled == interpreted == expected/<name>.out`
(byte-for-byte). It prints `PASS`/`FAIL` per program, a summary, and exits
nonzero on any failure.

Programs listed in [`SKIP`](SKIP) (one `<name>  <reason>` per line) are reported
`SKIP` and not run; the summary counts them separately and they do not fail the
suite. The mechanism is for any program minbasic cannot yet run portably; **no
programs are currently skipped**.

## The runnable-now subset (which programs are here, and why)

Of the **208** NBS programs (P001..P208), **207** are vendored and all run in
CI. The other **1** is excluded because minbasic cannot run it deterministically
*today*. Runnability was determined empirically (running each program through
minbasic), not guessed. The breakdown:

### Excluded — deferred feature (1)

The transcendental functions (SQR/SIN/COS/TAN/ATN/EXP/LOG) and the non-integer
`^` exponent are implemented (via `pkg/std/math`, a software/deterministic
library, so compiled and interpreted agree). One program remains excluded:

- **P131** — `RANDOMIZE`: needs an entropy source we have deferred (it would need
  Binate library support beyond `pkg/std/math`).

### Overflow → integer-index programs (3)

`P168`, `P174`, `P180` each convert an **overflowed** numeric (machine `+Inf`,
from an overflow or division by zero) to an **integer index** — `P168` an array
subscript (`Z(A^A)`, `A=9999`), `P180` an `ON…GOTO` index (`ON 1E-33/0 GOTO …`),
`P174` a `TAB` column (`TAB(9^(9^9))`). The conversion is `cast(int, …)`; its
result for a non-finite / out-of-range float is **defined as saturating**
(`+Inf → INT64_MAX = 9223372036854775807`) and host-independent, so all three
run in CI byte-identically across modes and ISAs.

### INPUT programs (all 8 kept)

All eight INPUT programs are kept, each with a canned `input/<name>.in` reply
stream that drives a correct, complete run: P107/P108/P109/P110 self-report PASS;
P111 exercises underflow-on-input → zero recovery; P112 exercises the full INPUT
exception/re-request battery (26 cases, each bad reply `?REDO`'d then re-supplied
as zeros — see "bugs found and fixed" item 5); P073 is OPTION-BASE-1 `DIM A(0)`
exploratory output; P203 is the zones-and-margin visual test.

P203 is a *visual* zone/margin test: minbasic's output is ECMA-55-conformant, but
its byte-level "first vs second" pairs differ by trailing whitespace in one case.
That is correct behaviour — a comma "generates one or more spaces to set the
columnar position to the beginning of the next print zone" (clause 14, eager) and
the standard does not trim trailing spaces, so a line that advances through zones
and then wraps keeps the (invisible) zone-fill spaces the test's simplified model
omits. The last-zone comma itself generates a clean end-of-line (no pad), as
required.

(P081, P084, P113 also contain `INPUT` but minbasic rejects them *before* the
read — deterministic error tests — so they are kept.)

### `RND` programs — kept as a minbasic-only regression oracle (13)

P130 P133–P141, P145 P146 P149 use `RND`. minbasic's RND is deterministic (a
fixed-seed xorshift64), so they run byte-identically in both modes and are kept
as a pure minbasic regression oracle. They are NOT cross-validated against bas55:
ECMA-55 leaves the RND sequence implementation-defined, so minbasic's output
differs from bas55's by construction. (P145/P146/P149 are actually RND
argument-list *error* tests — `RND` takes no argument — which minbasic rejects at
parse. P137's chi-square poker test runs a long RND loop; see the `errMsg`
note in `examples/TODO.md`.)

(The two ECMA-55 nonfatal-recovery cases once held back — `TAB(n) < 1` and
numeric-constant overflow — are likewise handled and kept; see "bugs found and
fixed" item 4 below.)

## Cross-validation against bas55 (development oracle)

During development the original 146-program cut was compared to bas55's `.ok`
files (CRLF-normalized; bas55's error-line path prefix ignored). bas55's fixtures
are **not** committed (GPL-3.0; see `PROVENANCE.md`). How that cut compares:

- **31** byte-identical to bas55.
- **25** differ *only* in numeric formatting — minbasic uses the ECMA-55
  reference `d = 6` with 5×15-column print zones; bas55 uses `d ≤ 8` with
  16-column zones. Both are within ECMA-55's latitude; the digit *values* match.
- **20** differ *only* because they are error tests whose diagnostic minbasic
  writes to the merged stdout stream where bas55 writes it to stderr — same
  exception, same line number (plus the column-width latitude above).
- **1** (P038) is a documented accept-or-reject case: the program tests the
  *non-standard* "adjacent operators" feature (`4 ^ -2`), which ECMA-55 lets a
  processor either accept or reject. bas55 accepts (computes `.0625`); minbasic
  rejects with a parse diagnostic. Both are conformant.
- **69** are error tests where bas55's `.ok` is empty (bas55 puts the diagnostic
  on stderr). minbasic emits its own diagnostic on stdout, frozen as the fixture.

No *unexplained* structural difference (wrong control flow, wrong integer, wrong
value) remained in the kept set after the bug fixes noted below.

**P008 and P030** were added later (when the nonfatal-recovery fix below landed),
so they are outside that 146-program bas55 cross-check. They are instead
validated against each program's *own* embedded NBS pass criteria — P008 prints
its `X` in column 1 in all four sections, P030 supplies `+INF` / `-INF` for the
overflowing `±3E99999` constants — plus the standard dual-mode byte-identical
assertion.

## minbasic bugs found and fixed while building this harness

All in `pkg/basic` (minbasic's own code); each verified compiled == interpreted
after the fix:

1. **READ into an array element.** `READ A(I)` (a subscripted target) failed to
   parse — READ only accepted scalar variables. ECMA-55 clause 16 allows any
   variable, including an array element. READ now shares INPUT's target grammar.
   (Surfaced by P094.)
2. **Infinity / NaN formatting.** Overflow / division-by-zero values printed as
   `+.Inf` / `-+.Inf` / `N.aN` (strconv's `Inf`/`NaN` spelling fed through the
   numeric-magnitude splitter). They now print as ` INF ` / `-INF ` / ` NAN `.
   (Surfaced by P028, P031, P035, P101.)
3. **Non-integer `^` exponent.** Previously returned a silent `1.0` placeholder
   (wrong answer). It is now computed correctly as `a^b` via `pkg/std/math.Pow`; a
   negative base with a non-integer exponent is the ECMA-55 fatal exception
   (clause 8). (Surfaced by P032, P033, P170, etc.)
4. **Nonfatal-exception recovery.** Two recoverable ECMA-55 exceptions were
   wrongly treated as fatal. (a) `TAB(n)` with a rounded `n < 1` (clause 14.4)
   terminated the run; it now recovers by using column 1 and continuing. (b) A
   numeric *constant* whose magnitude overflows the float range (`3E99999`,
   clause 8.5) was rejected as "malformed"; it now recovers to signed machine
   infinity (`±INF`) — the `±Inf` the float parser already returns — and
   continues. Each recovery is also REPORTED (clause 3.5 requires nonfatal
   exceptions to be reported): `RunSource` takes a separate `err` diagnostic sink
   through which a `?line N: …` line is emitted at the point of recovery, then
   execution continues. `cmd/run` points `err` at stdout (a single ordered
   transcript, as `cmd/basic` does for its REPL framing), so the report appears
   inline and both modes stay byte-identical; a host wanting diagnostics off the
   program stream can pass a different sink. (Surfaced by P008 and P030, now
   kept.)
5. **INPUT-reply validation.** The shared datum scanner accepts any run of
   characters, but an INPUT reply is stricter (ECMA-55 clauses 4, 15). INPUT now
   rejects (`?REDO FROM START`, the nonfatal re-request) a reply with a malformed
   unquoted datum — an *empty* datum between commas (`A,,B`) or one holding a
   character outside the unquoted-string set (`;`, `?`, `*`, `"`) — and a numeric
   datum that *overflows* (`1E99999`), which clause 15 makes an INPUT exception
   (unlike READ, where overflow recovers to machine infinity); underflow still
   recovers to 0. Numeric and string-length checks were already enforced. (DATA
   keeps the lenient scan — program-authored DATA isn't user input. Surfaced by
   P112, now kept.)
6. **Computed-overflow & division-by-zero reporting.** A computed arithmetic or
   `EXP` overflow (a finite-operand result reaching machine infinity) and division
   by zero are nonfatal ECMA-55 exceptions (clause 8.5): each is now reported
   (`?line N: numeric overflow` / `?line N: division by zero`) and execution
   continues with machine infinity — division by zero takes the numerator's sign,
   so `0/0` is `+INF` (it was `NAN`). Propagation of an already-infinite operand
   is not re-reported. This also corrected P028, whose previously-frozen fixture
   held a spurious self-`TEST FAILED` caused by the old `0/0 → NAN`. (Surfaced by
   P028/P122/P029; the new reports also touch P031/P035/P167/P168/P174/P177/P180/
   P183.)
