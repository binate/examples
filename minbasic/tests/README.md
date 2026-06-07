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

## The runnable-now subset (which programs are here, and why)

Of the **208** NBS programs (P001..P208), **172** are vendored. The other **36**
are excluded because minbasic cannot run them deterministically *today*.
Runnability was determined empirically (running each program through minbasic),
not guessed. The breakdown:

### Excluded — deferred feature (34)

The program reaches a `?… not yet supported` fatal: it uses a transcendental
function or a non-integer `^` exponent, or `RANDOMIZE` (needs an entropy source
we have deferred). `SQR` is now implemented (via `pkg/std/math.Sqrt`), so its
SQR-only programs are kept; the other transcendentals await further
`pkg/std/math` functions.

- transcendentals: SIN — P127 P165 · COS — P120 · TAN — P128 P129 P164 ·
  ATN — P119 P183 · EXP — P121 P122 P123 P166 P169 P175 P181 ·
  LOG — P124 P125 P126 P167 P171 P179 (P166 uses SQR but also EXP/LOG/TAN/ATN,
  so it stays here until those land)
- non-integer `^` exponent (needs exp()/log()): P025 P026 P029 P032 P033 P043
  P170 P173 P174 P176 P177 P182
- `RANDOMIZE`: P131

### Excluded — INPUT programs blocked on a minbasic conformance gap (2)

The other six INPUT programs (P073 P107 P108 P109 P110 P111) are now kept: each
has a canned `input/<name>.in` reply stream that drives a correct, complete run
(P107/P108/P109/P110 self-report PASS; P111 exercises the underflow-on-input →
zero recovery; P073 is OPTION-BASE-1 `DIM A(0)` exploratory output). Two remain
excluded because they surface a real (firsthand-verified) minbasic conformance
gap — vendoring them would freeze knowingly-wrong output:

- **P112** — INPUT-reply exception coverage: minbasic's unquoted-datum scanner
  accepts input-replies ECMA-55 (clause 13) says must raise a nonfatal INPUT
  exception — e.g. an *empty* unquoted datum between commas (`X,,Y` into
  `INPUT A$,B$,C$` yields an empty `B$`). The program reports
  `POSSIBLE TEST FAILURE IN 14 CASE(S)`. (Numeric targets are fine — `1;2` is
  correctly rejected; the gap is the unquoted/string-datum scanner.)
- **P203** — PRINT zone/margin: a comma in the *last* print zone must generate a
  clean end-of-line (clause 14), but minbasic pads the zone with trailing spaces
  before the newline, so P203 section 203.3's "first vs second" line-pair (case
  #4) differs by trailing whitespace. The earlier zone-advance cases all match.

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
   (wrong answer). It now raises a clean `?… not yet supported` fatal — the same
   deferral as the transcendentals it depends on (exp()/log()), so such programs
   land cleanly in the deferred-feature bucket instead of producing wrong output.
   (Surfaced by P029, P032, P033, P170, etc.)
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
