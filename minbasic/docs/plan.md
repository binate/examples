# minbasic — ECMA-55 Minimal BASIC interpreter (plan)

An embeddable interpreter for **ECMA-55 "Minimal BASIC"** (1st ed., Jan 1978 =
ANSI X3.60-1978 = ISO 6373), built as a Binate example. It doubles as a
demonstration of three things the language cares about: an **embeddable REPL**
satisfying the same contract shape as `pkg/binate/repl`, **dependency-injected
I/O** (the interpreter core reaches no low-level I/O directly), and idiomatic
Binate (tagged-union ASTs, managed/raw slices, refcounting, errors-as-values).

This is a living plan; milestones are incremental and each keeps the example
building (so it never reddens the repo's `build-all`).

---

## 1. Goals & constraints

- **Language target:** ECMA-55 Minimal BASIC, the whole standard (no extensions).
  Implemented incrementally, but INPUT and the full statement set are *in scope*,
  not deferred away (see Milestones).
- **Embeddable REPL:** expose a `ReplSession`-shaped contract (`Init` / `Step` /
  `SetPoll`) so a CLI, a test harness, or a future wasm host can each drive the
  same engine. We **duplicate** the small contract types from
  `pkg/binate/repl.bni` for now; the intent (yours) is to eventually hoist that
  interface into `pkg/stdx` or `pkg/std`, at which point minbasic imports it
  instead.
- **Injected I/O:** the interpreter core depends only on **I/O interfaces**, never
  on `pkg/bootstrap` or any fd/syscall. Exactly one package — the host's delegate
  impl — imports `pkg/bootstrap`. That isolation is the point: when
  `pkg/bootstrap` is eventually removed/renamed, only that one file changes.
- **Builds against the released bundle only** (`BUILDER_VERSION`, currently
  `bnc-0.0.7`) — no Binate source checkout. Must run **both compiled (`bnc`) and
  interpreted (`bni`)**, byte-for-byte identical, like every other example here.

## 2. Feasibility — what's been verified (not assumed)

Empirically probed against `bnc-0.0.7`, both modes:

- **Output / no-newline:** `bootstrap.Write(fd, *[]readonly uint8)` writes raw
  bytes with no forced newline → covers `PRINT` including trailing-`;`
  suppression and the inline `"? "` INPUT prompt. The `print(...)` builtin also
  emits without a newline. Works identically compiled + interpreted.
- **Input:** `bootstrap.Read(STDIN, buf)` does a real blocking `read(2)`; a
  byte-at-a-time loop yields one line per call and leaves the rest for the next
  INPUT. **INPUT is feasible in both modes.**
- **Numbers:** `float64` is first-class in `bnc-0.0.7` → it *is* the BASIC numeric
  type; ECMA-55 reals map straight onto IEEE-754 double. `pkg/std/strconv`
  provides `ParseFloat` (INPUT) and `FormatFloat` (PRINT scaffolding).
- **Avoid:** `__c_call` is **compile-only** (`bni` errors `unhandled IR opcode
  c_call`) — all real I/O goes through `pkg/bootstrap`, never raw `__c_call`.
- **Known compiler hazard (designed around):** `&slice[i]` (address-of a slice
  element) miscompiles to a wild pointer in `bnc-0.0.7` (tracked CRITICAL in
  `explorations/claude-todo.md`). minbasic never takes the address of a slice
  element — it indexes slices for read/write (fine) and passes whole
  managed-slices to `Write`/`Read`. No workaround in the code, just an idiom we'd
  use anyway.

## 3. Architecture

Two cleanly separated I/O seams — the separation Binate's own REPL documents as
the goal but hasn't yet built, which minbasic does from day one:

- **Category A — engine framing** (banner, prompts, syntax-error diagnostics):
  the duplicated **`ReplIO`** `@func`-struct sink, copied verbatim.
- **Category B — the BASIC program's own I/O** (`PRINT` output, `INPUT` reads):
  an injected **interface**, because BASIC program I/O is cohesive (formatted
  print with shared print-column state), wants multiple impls (real console,
  capture buffer for conformance tests, future wasm), and grows toward INPUT.
  Split so output ships before input without a breaking change:

  ```
  interface ConsoleOut { Write(s *[]readonly char) int }
  interface ConsoleIn  { ReadLine() (@[]char, bool) }   // lands with INPUT (M4)
  ```

The interpreter core takes `ConsoleOut` (and later `ConsoleIn`) at construction
and routes **all** `PRINT` emission through it — never `print`/`bootstrap.Write`
directly. `registerExterns` (Binate's REPL injects native VM bindings that way)
has **no analogue** here: there's no inner VM; `ConsoleOut` is the I/O-injection
mechanism.

### Proposed package layout (a starting point, adjustable)

```
minbasic/
  README.md                  WIP pointer → docs/plan.md; run instructions later
  docs/plan.md               this plan
  docs/ecma55-notes.md       (optional) full spec digest, vetted before commit

  pkg/io.bni  + pkg/io/      ConsoleOut / ConsoleIn interfaces (leaf; no deps).
                             Kept tiny + dependency-free so the host impl needn't
                             import the whole core just to satisfy them.

  pkg/basic.bni + pkg/basic/ the interpreter core. Imports only pkg/io,
                             pkg/stdx/slices, pkg/std/{strconv,errors},
                             pkg/binate/buf. NEVER pkg/bootstrap.
      contract.bn            duplicated ReplSession/ReplIO/StepResult/StepStatus/
                             ReplError (+ trivial completion predicate)
      token.bn / lex.bn      tokenizer (char-level; isDigit/isAlpha helpers)
      ast.bn                 Stmt / Expr tag-enum structs (Kind + wide fields)
      parse.bn               line → Stmt; expression parser (precedence below)
      value.bn               Value = { Kind; Num float64; Str @[]char }
      program.bn             line-number-ordered program store (slices.Append)
      env.bn                 variables (flat arrays), DIM arrays, DEF FNs
      eval.bn / expr.bn      statement execution + control stacks; expr eval +
                             intrinsics (ABS ATN COS EXP INT LOG RND SGN SIN SQR TAN)
      format.bn              ECMA-55 numeric PRINT formatting
      session.bn             basicSession : ReplSession (Init/Step state machine)
      *_test.bn              unit tests (lex/parse/eval/format)

  pkg/host.bni + pkg/host/   THE delegate impl — the *only* pkg/bootstrap importer.
                             bootstrapConsole : io.ConsoleOut/ConsoleIn over
                             bootstrap.Write/Read; a ReplIO sink over the same.

  cmd/run/main.bn            non-interactive: `run prog.bas` → RUN a program
  cmd/basic/main.bn          interactive REPL host; wires host.Console + ReplIO,
                             drives Init/Step

  tests/                     (M5) vendored NBS subset + our fixtures + runner
```

Dependency direction (strictly downhill): `cmd → {pkg/basic, pkg/host}`;
`pkg/host → {pkg/io, pkg/bootstrap}`; `pkg/basic → {pkg/io, stdx/slices,
std/strconv, std/errors, buf}`. The core never sees `pkg/bootstrap`.

### REPL contract mapping

Duplicate from `pkg/binate/repl.bni`: `ReplIO`, `StepResult`, `StepStatus` (+
`STEP_*`), `ReplError`, `ReplSession`. BASIC-specific simplifications:

- **Completion is trivial.** Every BASIC line is one complete turn (a numbered
  line stored, or an immediate-mode statement run) — no bracket-balanced
  multi-line accumulation. The completeness predicate is constant `depth == 0`,
  so `Step` never returns `STEP_NEED_MORE`; the EOF handling
  (`STEP_EOF_CLEAN`/`_UNBALANCED`) carries over unchanged.
- **`Counter`** (the `In[n]` index) is meaningless for line-numbered BASIC — keep
  the field for shape compatibility, host ignores it. `Depth` (always 0) drives
  the single `READY`/`>` prompt.
- **`SetPoll`** kept inert in v1 (as Binate's is); a later stage can wire it to
  break a running `RUN` on Ctrl-C.
- Constructor returns setup errors **as values** (`@[]ReplError`), never
  `print`+`exit` — same discipline as `NewReplSession`.

The host loop is the standard `Init()` then `for { render prompt from r.Depth;
read one line; r = Step(line, eof); break on EOF }`. The host owns the read
(byte-at-a-time via the injected `ConsoleIn`); the engine is push-driven.

## 4. BASIC semantics & internal representation

- **Value model is tiny:** a number (`float64`) **or** a string (`@[]char`, ≤18
  chars). No string arrays, no concatenation, no string functions; string
  compare only `=`/`<>`. → `Value = { Kind int; Num float64; Str @[]char }`.
- **AST** is the codebase idiom: a `const ( … iota )` kind enum + one wide struct
  per category (`Stmt`, `Expr`) carrying the superset of fields; reader dispatch
  is an `if/else-if` chain on `.Kind` (not `switch`, not interfaces). Children are
  `@Expr` / `@[]@Expr`.
- **Variables** are a small dense namespace → **flat fixed arrays**, no hashmap:
  scalars `A`..`Z` and `A0`..`Z9` → `[286]Value` (index `(c-'A')*11 + slot`);
  string vars `A$`..`Z$`; arrays `A`..`Z` → `[26]@[]Value`. Numeric default 0.
- **Growth without `append`:** `slices.Append[T]` (explicit type args) for the
  program store; `buf.CharBuf` for building PRINT/INPUT text; `DIM A(10)` is one
  `make_slice(Value, 11)` (bound+1) up front.
- **Expressions:** precedence high→low `^` · unary `-` · `* /` · `+ -`. Two
  conformance traps to honor: **`^` is LEFT-associative** (`A^B^C = (A^B)^C`) and
  **unary `-` binds looser than `^`** (`-A^B = -(A^B)`); `0^0 = 1`. `INT` is
  **floor** (toward −∞), trig in radians, `RND` takes no argument.
- **Numeric PRINT format** is the most-tested, partly implementation-defined area
  — see Open Decision (1).
- **Exceptions:** ECMA-55 splits *nonfatal* (div-by-zero → signed ∞, overflow →
  signed ∞, all INPUT errors → re-request the whole reply, underflow → 0) from
  *fatal* (SQR/LOG bad domain, subscript out of range, RETURN without GOSUB,
  ON…GOTO out of range, READ out-of-data, …). Model an `evalError` with a
  fatal/nonfatal flag; nonfatal paths recover, fatal paths unwind to the prompt.

Authoritative spec text: `https://buraphakit.sourceforge.io/ECMA-55.TXT`
(faithful plain-text, preserves clause numbering) cross-checked against the
official ECMA PDF and the bas55 reference impl. A full implementer digest is
written at `/tmp/minbasic-ecma55.md` (offer to vet + commit as
`docs/ecma55-notes.md`).

## 5. Milestones (each keeps the example green)

**Status (2026-06-05).** M0 done. **M1 slices 1, 2a, 2b** are done and verified
(byte-identical in both modes, hygiene 7/7): slice 1 = `LET` / `PRINT` /
numeric+string expressions / the ECMA-55 numeric formatter; slice 2a = control
flow (`GOTO`, `IF <rel> THEN <line>`, `FOR`/`NEXT` with the exact block
equivalence — zero-trip, `v==limit` runs the body, limit/step evaluated once);
slice 2b = `TAB` + the deterministic intrinsics `ABS`/`SGN`/`INT`. So the
**non-interactive deterministic core (M1) is complete except the math-dependent
intrinsics**: the transcendentals (`SQR`/`SIN`/`COS`/`TAN`/`ATN`/`EXP`/`LOG`) are
parsed but deferred until `pkg/std/math` ships them (the bundle has no float
math — not rolling our own), and `RND`/`RANDOMIZE` are deferred (need a PRNG +
entropy decision); all of these reserve their names and surface a clean
`?<fn> not yet supported` fatal. **M2** (`GOSUB`/`RETURN`, `ON…GOTO`,
`READ`/`DATA`/`RESTORE`, `DIM` + numeric arrays + `OPTION BASE`, single-line
`DEF FN`) is done and verified — the **non-interactive language is complete**,
bar the deferred math-dependent intrinsics. **M3** (the embeddable REPL —
`basicSession : ReplSession`, incremental line edits, immediate mode,
`RUN`/`LIST`/`NEW`, driven by `Init`/`Step`) and **M4's `INPUT`** (the injected
`ConsoleIn` seam, atomic-validate + `?REDO FROM START` re-request, one shared
stdin reader for the REPL and INPUT) are done and verified. Remaining: **M4's
`RND`/`RANDOMIZE`** (a PRNG + an entropy decision for RANDOMIZE), then **M5** (NBS
conformance harness) — plus the deferred transcendentals once `pkg/std/math`
lands. (M3 ships a marked `*func` temp for the REPL sinks, tracked in `TODO.md` +
`explorations/claude-todo.md` — restore `@func` when the destructor defect is
fixed.) minbasic needs a main toolchain (interface-vtable + IR-gen-OOM fixes, both
in main, not the pinned `bnc-0.0.7`) — build against a main bundle via
`BINATE_BUNDLE`.

- **M0 — skeleton + wiring.** Create `pkg/io`, the core package shell, and a
  trivial `cmd/run` that builds and prints a banner; confirm it builds compiled +
  interpreted and is picked up by `build-all`. Add the per-example `README.md`.
- **M1 — non-interactive RUN, deterministic core.** Lexer + parser + program
  store + evaluator for: `LET`, `PRINT` (numbers/strings, `,`/`;` zones,
  newline suppression, `TAB`), `GOTO`, `IF rel THEN line`, `FOR/NEXT`, `END`,
  `STOP`, `REM`, full expressions + precedence + the intrinsic functions, and the
  numeric PRINT formatter. `run prog.bas` reads a file (`bootstrap.Open` in the
  host delegate), runs it, PRINTs through the injected `ConsoleOut`. No INPUT, no
  REPL yet.
- **M2 — rest of the non-interactive language.** `GOSUB`/`RETURN`, `ON…GOTO`,
  `READ`/`DATA`/`RESTORE`, `DIM` + arrays + `OPTION BASE`, `DEF FN`.
- **M3 — embeddable REPL.** `basicSession : ReplSession`: numbered lines edit the
  store, immediate-mode statements execute now, `RUN`/`LIST`/`NEW`. `cmd/basic`
  drives `Init`/`Step`, framing via `ReplIO`, program I/O via `ConsoleOut`.
- **M4 — INPUT (+ RANDOMIZE/RND).** `ConsoleIn` delegate (line-buffered
  `bootstrap.Read`), the `INPUT` statement with atomic validate + re-request on
  error.
- **M5 — conformance harness.** Vendor the public-domain NBS `.BAS` subset,
  generate our *own* output fixtures, a `run.sh` that diffs. (Wiring this into CI
  is a separate decision — I won't add CI automation without asking.)

Each milestone bundles unit tests (`*_test.bn`) for the code it adds.

## 6. Test suite

The **NBS (NIST) Minimal BASIC suite** (208 programs `P001`–`P208`) lives in the
bas55 repo. The `.BAS` programs are **US-government work → public domain**, safe
to vendor (with a `PROVENANCE.md` note: NBS SP 500-70 v1/v2 + John Gatewood Ham's
transcription). bas55's `.ok`/`.eok` fixtures are **GPL-3.0 — do NOT vendor**; we
**regenerate our own** fixtures from minbasic and review them once. 205/213 run
with no interactive input; the first cut excludes the genuinely-interactive INPUT
programs (`P107–P112`, `P203`), the nondeterministic `P131` (RANDOMIZE), and
initially defers the RND battery (`P130`, `P132–P142`) and deepest
float-accuracy tests (`P117–P128`) until our RND + numeric formatting are pinned.

```
tests/ PROVENANCE.md  nbs/P###.bas  expected/P###.out  run.sh
```
Error tests (expected rejection) assert non-zero exit / a diagnostic rather than
diffing bas55's specific error text.

## 7. Decisions

**Open:**

1. **Numeric PRINT format target.** (Tabled — revisit before M1's formatter +
   M5's fixtures.) ECMA-55 leaves it partly implementation-defined and the
   natural targets diverge:
   - **(recommended) Standard reference:** significance-width d=6, 5 zones × 15
     cols — what the spec's own examples use; cleanest to test against the
     standard's stated outputs.
   - **bas55-compatible:** IEEE double, d≤8, 16-col zones — lets us sanity-check
     against bas55's runs, but ties fixtures to bas55's formatting latitude.
   This picks the formatting algorithm *and* what our fixtures encode.

**Resolved:**

2. **I/O delegate realization → direct `import "pkg/bootstrap"`** in the single
   `pkg/host` delegate. One import, simplest, and *is* exactly the "only the
   delegate touches it" isolation. (The copy-the-`.bni` hack was only worth it if
   the bundle lacked `bootstrap.bni`; it ships it. Renaming the package is not an
   option regardless — externs are keyed by package-qualified name in both
   backends, so a rename breaks both modes, and there are no Binate bodies to
   copy.)
3. **ECMA-55 digest vendored** → [`docs/ecma55-notes.md`](ecma55-notes.md)
   (implementer-grade, sourced from a faithful plain-text reproduction
   cross-checked against the official ECMA PDF + bas55).

## 8. Non-goals (for now, by nature of Minimal BASIC — not silent scope cuts)

ECMA-55 *Minimal* BASIC deliberately excludes: string concatenation/substring/
functions, string arrays, multi-statement lines, `ELSE`, `WHILE`, structured
control, file I/O within the language, matrices. These aren't deferrals — they're
outside the standard. Anything the standard *does* include (INPUT, DEF, arrays,
the full PRINT formatting) is in the milestones above.
