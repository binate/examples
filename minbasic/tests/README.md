# minbasic NBS conformance / regression harness

This directory runs minbasic against the public-domain **NBS Minimal BASIC test
programs** (NBS SP 500-70; see `PROVENANCE.md`). It is a **regression oracle**:
the committed fixtures in `expected/` are minbasic's own frozen output, reviewed
and (where comparable) cross-checked against the bas55 reference. It is *not* an
independent oracle.

## Layout

- `nbs/` — the vendored `P*.BAS` programs (public domain), the runnable-now subset.
- `expected/` — `<name>.out`, the frozen expected output (minbasic's own bytes).
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

Of the **208** NBS programs (P001..P208), **146** are vendored. The other **62**
are excluded because minbasic cannot run them deterministically *today*.
Runnability was determined empirically (running each program through minbasic),
not guessed. The breakdown:

### Excluded — deferred feature (39)

The program reaches a `?… not yet supported` fatal: it uses a transcendental
function or a non-integer `^` exponent (both need `pkg/std/math`, not yet
landed), or `RANDOMIZE` (needs an entropy source we have deferred).

- transcendentals: SQR — P117 P118 P132 P142 P166 P172 · SIN — P127 P165 ·
  COS — P120 · TAN — P128 P129 P164 · ATN — P119 P183 ·
  EXP — P121 P122 P123 P169 P175 P181 · LOG — P124 P125 P126 P167 P171 P179
- non-integer `^` exponent (needs exp()/log()): P025 P026 P029 P032 P033 P043
  P170 P173 P174 P176 P177 P182
- `RANDOMIZE`: P131

### Excluded — interactive INPUT (8)

The program reaches a live `INPUT` and reads stdin (out of scope for this cut):
P073 P107 P108 P109 P110 P111 P112 P203.

(P081, P084, P113 also contain `INPUT` but minbasic rejects them *before* the
read — deterministic error tests — so they are kept.)

### Excluded — nondeterministic / RND (13)

The program uses the `RND` function. minbasic's RND is deterministic, but it is
*our own* PRNG sequence (ECMA-55 leaves the sequence implementation-defined), so
these cannot be dev-validated against bas55: P130 P133 P134 P135 P136 P137 P138
P139 P140 P141 P145 P146 P149.

### Excluded — pending a semantics decision (2)

minbasic currently makes a recoverable (nonfatal) ECMA-55 exception fatal, which
diverges from the standard and from bas55. These are real minbasic conformance
gaps, held back from this cut until the exception classification is decided
(rather than freeze knowingly-wrong output):

- **P008** — `TAB(n)` with `n < 1`: minbasic terminates; ECMA-55, bas55, and
  P008's own pass criterion say this is **nonfatal** (report, recover to column 1,
  continue).
- **P030** — a numeric *constant* that overflows (`3E99999`): minbasic rejects it
  as "malformed"; ECMA-55 says constant overflow is **nonfatal** (recover with
  machine infinity, continue).

## Cross-validation against bas55 (development oracle)

During development the 146 kept fixtures were compared to bas55's `.ok` files
(CRLF-normalized; bas55's error-line path prefix ignored). bas55's fixtures are
**not** committed (GPL-3.0; see `PROVENANCE.md`). How the kept set compares:

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
