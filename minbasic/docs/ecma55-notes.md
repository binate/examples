# ECMA-55 Minimal BASIC — Implementer's Digest

Source standard: **Standard ECMA-55, "Minimal BASIC", 1st edition, January 1978** (ISO equivalent: ISO 6373:1984; ANSI equivalent: ANSI X3.60-1978). Withdrawn/historical. This is a faithful, implementer-oriented digest assembled from the reproductions below; section numbers refer to ECMA-55's own numbered clauses.

## Sources used (and authority)

1. **`https://buraphakit.sourceforge.io/ECMA-55.TXT`** — plain-text digitization of the full ECMA-55 standard (by John Gatewood Ham, author of an ECMA-55 compiler). This is the *primary* source for this digest: it preserves ECMA's clause numbering and BNF verbatim. Highly faithful; internally consistent with the official clause structure. **Authority: high (faithful reproduction of the normative text).**
2. **`https://www.ecma-international.org/wp-content/uploads/ECMA-55_1st_edition_january_1978.pdf`** — the **official ECMA PDF** (the authoritative normative document, free). Used as the cross-check authority. (Could not be fully machine-fetched here — exceeds fetch size limit — but it is the canonical text; the .TXT above tracks it.) **Authority: definitive.**
3. **`https://standard-ecma-55-minimal-basic.lab-allen.fr/`** — a clean HTML reproduction of ECMA-55, clause-by-clause. Used to confirm PRINT/zone/format wording. **Authority: high (secondary reproduction).**
4. **bas55 by Jorge Giner Cordero** — `https://jorgicor.niobe.org/bas55/bas55.html` and `https://github.com/jorgicor/bas55`. A well-regarded conforming implementation. Used to confirm *concrete* implementation choices for the implementation-defined parameters. **Authority: reference implementation, not normative.**
5. `https://en.wikipedia.org/wiki/Minimal_BASIC` and Internet Archive `archive.org/details/ecma-55-1978` (catalog/overview only).

Where a value is **implementation-defined** by the standard, this digest gives the standard's *minimum* requirement AND the conventional concrete value (from the standard's own non-normative remarks and from bas55), clearly flagged.

---

## 1. Program / line format (clause 5)

- **A program** is a sequence of **lines**, each: `line-number statement end-of-line`. The final line must be the **end-line**: `line-number END end-of-line`.
- **Line number**: 1 to 4 decimal digits → `line-number = digit [digit [digit [digit]]]`. Integer value must be **positive nonzero** (1..9999). Leading zeros are allowed and have no effect.
- **Ordering**: statements/lines **shall occur in strictly ascending line-number order**. (Duplicate line numbers are not allowed.)
- **One statement per line.** There is no statement separator (no `:`). Exactly one statement per line.
- **Line length**: a conforming program's lines may contain **up to 72 characters**, NOT counting the end-of-line indicator.
- **end-of-line**: an implementation-defined indicator terminating each line (not one of the 72 chars).
- **END** (clause 5.4): the `END` statement marks the **physical end of the main program body** AND **terminates execution** when reached. END must be the highest-numbered line. There is exactly one END, as the last line.
- **REM** (clause 23): `remark-statement = REM rest-of-line`. A remark line is a no-op; reaching it during execution proceeds to the next line with no other effect. Everything after `REM ` (to end-of-line) is commentary.
- **Spaces** (clause 5.4): Spaces shall NOT appear at the start of a line, nor *within* a keyword, nor within a line-number, nor within a multi-character constant/identifier where prohibited. Keywords shall be **preceded by at least one space** and, unless at end of line, **followed by at least one space**. Spaces are otherwise generally allowed between tokens. (Note `GO TO`/`GO SUB` may have spaces between the two words — see clause 12.)
- **Character set** (clause 4): a defined set of letters (A–Z, uppercase), digits, and special characters. Lowercase is not part of the minimal required set.

---

## 2. Data model

### 2.1 The single numeric type (clauses 6, 7)

- There is **exactly one numeric type**. All numeric variables, constants, and expression results are of this one type (a real/floating value). No integer-vs-real distinction at the language level.
- **Precision (clause 6.4)**: implementation-defined, **at least six (6) significant decimal digits**. Implementations may round to their precision.
- **Range (clause 6.4)**: implementation-defined, **at least 1E-38 to 1E+38** (in magnitude). I.e., must represent magnitudes across at least that range; there is also a "machine infinitesimal" (smallest positive) and "machine infinity" (largest magnitude) per implementation.
- **Numeric constants** (`numeric-rep`, clause 6.2): optional sign, significand (digits with optional decimal point / full-stop), optional exponent part `E` sign? digits. E.g. `1`, `-3.14`, `.5`, `2.5E-3`, `1E10`. The `E` is uppercase. Grammar (6.2):
  ```
  numeric-constant = sign? numeric-rep
  numeric-rep      = significand (E sign? integer)?
  significand      = integer fraction? / fraction
  fraction         = . integer
  ```

### 2.2 Numeric variables (clause 7)

- `simple-numeric-variable = letter [digit]` — a single letter, optionally followed by a single digit. So `A`, `B`, `X`, `A0`, `A1`, ... `Z9`. (Exactly one letter + at most one digit.)
- Implicitly declared by first appearance. Initial value before assignment is **implementation-defined** (clause 7.4) — NOT specified to be zero, and using an uninitialized variable is **not** itself a defined exception (clause 7.6 only *recommends* explicit initialization).

### 2.3 Arrays (clause 18)

- `numeric-array-name = letter` (a single letter — note: an array `A(...)` shares its letter with… nothing problematic, but note the letter namespace; `A` as array and `A` as simple variable would collide on the same letter — arrays are named by a single letter).
- `numeric-array-element = numeric-array-name ( subscript [, subscript] )` — **1 or 2 dimensions only**. (No 3+ dimensional arrays.)
- Subscripts are numeric expressions, **rounded to the nearest integer** to index.
- **DIM** (18.2): `DIM array-declaration (, array-declaration)*` where `array-declaration = letter ( integer [, integer] )`. The integers are the **upper bounds**.
- **Lower bound / OPTION BASE** (18.4, 19):
  - `OPTION BASE 0` (default) → subscripts range **0 .. upper-bound** inclusive.
  - `OPTION BASE 1` → subscripts range **1 .. upper-bound** inclusive.
  - The `OPTION` statement, if present, must appear on a **lower-numbered line than any DIM or any array reference**, and there may be at most one.
- **Default (implicit) dimensioning**: an array used without a DIM has each upper bound = **10**. So default range is **0..10** (11 elements per dim) under base 0, or **1..10** (10 elements) under base 1.
- **Subscript out of range** → **fatal exception** (18.5).

### 2.4 String support — EXACT scope (clauses 6, 7, 11, 15, 16)

This is deliberately minimal. Minimal BASIC has strings but almost no string machinery:

- **String variables exist**: `string-variable = letter $` — a single letter followed by `$`. E.g. `A$`, `B$`, ... `Z$`. (Only simple string variables; **there are no string arrays**.)
- **String length**: a string variable holds 0 to **18 characters** (the null/empty string up to 18). Assigning a string datum with **more than 18 characters** to a string variable is an exception (fatal for LET/READ, nonfatal-retry for INPUT).
- **String constants**: `string-constant = " ... "` (quoted-string). Value is exactly the characters between the quotes; **spaces are significant** (not ignored). A string constant's length is limited only by the line length (so a string constant *literal* can exceed 18 chars — but it can then only be used as a PRINT item, since it cannot be assigned to an 18-char-max variable).
- **String expressions** (clause 7.2): `string-expression = string-variable / string-constant`. That's it — **no concatenation operator**, no substring, no string-building expressions.
- **String operations available**:
  - **LET** to a string variable: `LET A$ = <string-expression>` (assign a variable or a constant).
  - **PRINT** of string expressions.
  - **INPUT / READ / DATA** of string values.
  - **Relational comparison** of strings: only **`=` and `<>`** (equality / inequality). Equality holds iff same length and identical character sequence. **No ordering** (`<`, `>`, `<=`, `>=`) on strings.
- **String functions**: **NONE.** Minimal BASIC has no `LEN`, no `LEFT$`/`MID$`/`RIGHT$`, no `CHR$`/`ASC`/`STR$`/`VAL`, no concatenation. (These are extensions in later/full BASIC, not in ECMA-55.)

**Value model takeaway for an implementer:** a value is either (a) one numeric (single real type, ≥6 sig digits, range ≥1E±38), or (b) a string of 0..18 chars. Variables are: simple numeric (`letter[digit]`), numeric array element (1–2 D, `letter(...)`), or string (`letter$`). No string arrays, no other aggregate types.

---

## 3. Complete statement set (syntax + semantics)

### 3.1 LET (clause 11)
```
numeric-let-statement = LET numeric-variable = numeric-expression
string-let-statement  = LET string-variable  = string-expression
```
Evaluate RHS, assign to LHS variable. `LET` keyword is **required** (no implicit-LET in Minimal BASIC). Exception: string datum too long → fatal (11.5).

### 3.2 PRINT (clause 14)
```
print-statement = PRINT print-list?
print-list      = (print-item? print-separator)* print-item?
print-item      = expression / tab-call
tab-call        = TAB ( numeric-expression )
print-separator = , | ;
```
- **Items**: numeric expressions, string expressions, and `TAB(n)`.
- **`;` (semicolon)** separator: generates the **null string** (no spacing) — items abut. (Numbers still carry their own leading sign/space and trailing space, so adjacent numbers don't run together.)
- **`,` (comma)** separator: advances output to the **start of the next print zone**; if the current zone is the **last** on the line, it generates an **end-of-line** instead (so output wraps to the next physical line at column 1).
- **Trailing separator**: if the print-list ends WITH a `,` or `;` (pending/no final item), **no end-of-line is generated** — the cursor stays put, so the next PRINT continues on the same line. If the print-list does **not** end with a separator (or is empty), an **end-of-line IS generated** at the end.
- **Empty `PRINT`**: generates an end-of-line → a blank line (or completes the current partial line).
- **TAB(n)** semantics (14.4): evaluate the argument, **round to nearest integer n**. If `n < 1` → **exception**. If `n > m` (the margin / line width), reduce modulo m: `n := n - m*INT((n-1)/m)` so `1 ≤ n ≤ m`. Then: if current columnar position ≤ n, emit spaces to reach column n; if current position > n, emit end-of-line then spaces to column n on the new line.
- **Numeric output format**: see §5 (this is the most-tested area).
- **String output**: the string's characters verbatim (no quotes, no added spaces).

### 3.3 INPUT (clause 15)
```
input-statement = INPUT variable-list
variable-list   = variable (, variable)*
```
- Prompts the user (interactive mode) then reads an **input-reply**: a line `input-list end-of-line`, where `input-list = padded-datum (, padded-datum)*`, `padded-datum = space* datum space*`, `datum = quoted-string / unquoted-string`.
- **Prompt**: implementation-defined; the standard *recommends* (15.6) a **question mark followed by a single space**: `? `.
- Each datum is assigned **in order** to the variables. **Type must match**: a numeric variable requires a datum that is a valid numeric-constant; a string variable accepts a quoted string or an unquoted string. An unquoted string that is a valid number may go to either.
- **Validation is atomic** (15.4): **no assignment happens until the whole reply is validated** for type of each datum, count of items, and range. On any failure the entire reply is rejected.
- **INPUT exceptions are all NONFATAL** (15.5) — recommended recovery is to **re-request the whole input-reply**:
  - type mismatch (datum type ≠ variable type),
  - **insufficient** data (fewer data than variables),
  - **too much** data (more data than variables),
  - numeric overflow while evaluating a datum,
  - string datum > 18 chars.

### 3.4 READ / DATA / RESTORE (clauses 16, 17)
```
read-statement    = READ variable-list
data-statement    = DATA datum (, datum)*       (datum = quoted-string / unquoted-string / numeric-constant)
restore-statement = RESTORE
```
- All **DATA** statements in the program (in textual line order, left-to-right within a line) form **one global data sequence**. A DATA line is a no-op when reached during execution.
- A **conceptual pointer** starts at the first datum at program start. **READ** assigns successive data to its variables, advancing the pointer past each. 
- **Type matching** (16.4): numeric variable needs an unquoted-string that is a valid numeric-constant; string variable accepts quoted or unquoted strings. An unquoted numeric-looking string may feed either a numeric or string variable.
- **RESTORE** resets the pointer to the **beginning** of the data sequence.
- **READ/DATA exceptions** (16.5):
  - more data needed than remain in the sequence (**out of data**) → **fatal**;
  - assign a string datum to a numeric variable → **fatal**;
  - numeric overflow evaluating a datum → **nonfatal** (supply machine infinity, signed, and continue);
  - string datum > 18 chars → **fatal**.

### 3.5 GOTO / GO TO (clause 12)
```
goto-statement = GO space* TO line-number
```
`GOTO` or `GO TO` (space between GO and TO permitted). Transfers control to the named line. **The referenced line must exist in the program.**

### 3.6 ON … GOTO (clause 12)
```
on-goto-statement = ON numeric-expression GO space* TO line-number (, line-number)*
```
Evaluate expression, **round to integer** k. Select the k-th line-number (1-based, left-to-right) and continue there. **Exception (fatal)** if k < 1 or k > number of line-numbers listed.

### 3.7 GOSUB / GO SUB and RETURN (clause 12)
```
gosub-statement  = GO space* SUB line-number
return-statement = RETURN
```
Modeled by a **stack of line-numbers**. GOSUB pushes the GOSUB line's number and jumps to the target. RETURN pops the top number and continues at the line **following** the popped GOSUB line. The numbers of GOSUBs and RETURNs need not balance over a run. **Exception (fatal)**: RETURN with an empty stack (no matching GOSUB).

### 3.8 IF … THEN (clause 12)
```
if-then-statement     = IF relational-expression THEN line-number
relational-expression = numeric-expression relation numeric-expression
                      | string-expression equality-relation string-expression
relation              = = | < | > | <= | >= | <>
equality-relation     = = | <>
```
- **THEN is followed ONLY by a line-number** — NOT a statement. (There is no `IF…THEN <statement>` and no `ELSE` in Minimal BASIC.) If the relation is true, control transfers to that line; if false, execution falls through to the next line.
- **Relational operators**: `=`, `<`, `>`, `<=`, `>=`, `<>`. (`<=` is `<` then `=`, etc.)
- **Numeric** comparisons use all six relations. **String** comparisons use only `=` and `<>` (equality is same-length + identical chars).

### 3.9 FOR / NEXT (clause 13) — see §4 for exact semantics
```
for-statement  = FOR control-variable = initial-value TO limit (STEP increment)?
next-statement = NEXT control-variable
```
`control-variable` is a **simple-numeric-variable**. `initial-value`, `limit`, `increment` are numeric expressions. STEP default = **+1**.

### 3.10 DIM (clause 18)
`DIM array-declaration (, array-declaration)*` — declares array upper bounds (1 or 2 dims). See §2.3.

### 3.11 DEF — single-line user functions (clause 10)
```
def-statement           = DEF numeric-defined-function parameter-list? = numeric-expression
numeric-defined-function = FN letter
parameter-list          = ( simple-numeric-variable )
```
- Names: `FNA`..`FNZ` (FN + one letter). **Single-line only** — the function body is a single numeric expression (no multi-line DEF, no FNEND).
- **0 or 1 parameter** (one simple numeric variable). The parameter is **local** to the definition (shadows any same-named outer variable). Variables in the body other than the parameter refer to the **global** program variables.
- The body expression is **not evaluated until the function is referenced**.
- The DEF must appear on a **lower-numbered line than the first reference** to that function.
- A function may call other defined functions but **not itself** (no recursion; no reference to the function being defined).
- Returns a numeric value (functions are numeric-only — no string functions).

### 3.12 OPTION BASE (clause 19)
`OPTION BASE 0` or `OPTION BASE 1`. Sets array lower bound. Must precede any DIM/array reference; at most one. See §2.3.

### 3.13 STOP (clause 12)
`STOP` — **terminates the program** (same effect as reaching END, but may appear anywhere).

### 3.14 END (clause 5)
`END` — last line; marks physical end and terminates execution when reached.

### 3.15 RANDOMIZE (clause 20)
`RANDOMIZE` — reseeds RND to an **unpredictable** starting point. Without any RANDOMIZE, a program's RND sequence is **reproducible** (same sequence every run). See §6 (RND).

---

## 4. FOR/NEXT exact iteration semantics (clause 13)

The standard defines FOR/NEXT by an **exact block-equivalence**. For
```
FOR v = a TO b STEP s
   (block)
NEXT v
```
the meaning is:
```
        LET own1 = b           ' limit, evaluated ONCE
        LET own2 = s           ' increment (step), evaluated ONCE; default +1
        LET v    = a           ' control variable initialized
line1:  IF (v - own1) * SGN(own2) > 0 THEN line2     ' loop-exit / zero-trip test
           (block)
        LET v = v + own2
        GOTO line1
line2:  (continue in sequence, after NEXT)
```
Key consequences (what test suites check):
- **Limit and step are evaluated once**, at loop entry (changing the expressions' variables inside the body does NOT change the limit/step). The **control variable v is a real, ordinary variable** and is updated as shown.
- **Zero-trip**: the body is **skipped entirely** if the exit test is already true on entry. With **positive step** (`SGN(own2)>0`), that means skip when `v > b` initially (a > b). With **negative step**, skip when `v < b` initially (a < b). With **step 0**, `SGN(0)=0` so the test is `0 > 0` = false → loops **forever** (until other exit) — the standard does not forbid step 0.
- **Termination test** is `(v - limit) * SGN(step) > 0` — i.e. for positive step, exit when v exceeds limit; for negative step, exit when v drops below limit. The boundary value (v == limit) **does** execute the body (test is strict `>`).
- **Final value of the control variable** after normal loop exit (via NEXT) is the **first value not used** — i.e. v has already been incremented past the limit (it equals the value that failed the test). (Clause 13.6.)
- **NEXT v must name the same control variable** as its FOR; FOR/NEXT blocks must be properly nested (a FOR is matched by a NEXT with the same variable; overlapping/crossed loops are not allowed). Mismatched/unmatched FOR/NEXT is an error (the standard requires proper pairing/nesting; violations are exceptions detected by the implementation).

---

## 5. Numeric PRINT/output format (clause 14 + clause on numeric representation) — EXHAUSTIVE

This is the highest-value area for conformance. Two implementation parameters govern it:
- **significance-width `d`** — number of significant decimal digits printed. Standard requires **d ≥ 6**. (Common concrete values: **d = 6** in the standard's own examples; bas55 uses up to **8** significant digits.)
- **exrad-width `e`** — number of digits in the exponent ("exrad"). Standard requires **e ≥ 2**. (bas55 uses 3.)

### 5.1 Sign and surrounding spaces (mandatory)
Every printed number is: **[sign-char] digits... [trailing space]**, where the sign-char is a **leading space for positive (and zero)** or a **leading minus `-` for negative**. A **single trailing space** always follows the number. (So `PRINT 1;2` → `␣1␣␣2␣`, and a positive number occupies one extra leading column vs. its digits.)

### 5.2 Choice of format (unscaled "fixed" vs scaled "E"-notation)
A number is printed in one of two notations:
- **Implicit-point unscaled (integer form)**: if the number can be represented **exactly as an integer using d or fewer digits**, it is printed as an integer with **no decimal point** (and no exponent). E.g. with d=6: `3` prints as `␣3␣`, `1000` as `␣1000␣`.
- **Explicit-point unscaled (plain decimal)**: used when the value can be represented with **d or fewer significant digits** in plain decimal notation **no less accurately** than in scaled notation. Printed with a decimal point (full-stop), up to d significant digits; **trailing zeros in the fraction may be omitted**. A magnitude **< 1** prints with **no digit left of the point** (e.g. `.5`, `.000001`).
- **Explicit-point scaled (E notation)**: used otherwise (very large or very small magnitudes that can't be shown accurately in d digits unscaled). Format: **`significand E sign integer`** where the significand `x` satisfies `1 ≤ x < 10`, printed with **exactly d digits of precision**, and the exponent is signed with e-width digits.

**The canonical threshold example (d = 6):**
- `10^-6` prints as **`.000001`** (still expressible in ≤ d digits unscaled, no accuracy loss).
- `10^-7` prints as **`1.E-7`** (would lose accuracy unscaled → scaled form). 

So with d=6, the smallest magnitude shown in plain decimal is about `1E-6`; below that it switches to E-notation. On the large end, integers up to 6 digits print plain; larger values that need >d digits go to E-notation. (The exact crossover magnitudes scale with the chosen d.)

### 5.3 Significand details for scaled form
The significand is `1 ≤ x < 10`, printed with exactly d significant digits (so one digit before the point and d−1 after, e.g. d=6 → `1.23456E+10`). The `E` is uppercase, followed by the exponent **sign** (`+` or `-`) and the exponent digits.

(Note: the standard's example writes `1.E-7` — i.e. when the significand is exactly 1, trailing fractional digits may be elided just as in unscaled form, leaving `1.`. Implementations vary on whether they print `1.E-7` vs `1.00000E-07`; this is within the latitude the standard's "up to d digits / trailing zeros may be omitted" wording allows. Flag for conformance: pin your own choice and test against your target suite.)

### 5.4 Print zones / line layout (clause 14)
- A print line is divided into a fixed number of **print zones**; the **count and width are implementation-defined**, but each zone (except possibly the last) must be at least **`d + e + 6`** characters wide.
- The standard's **non-normative remark** gives the conventional layout: **5 print zones of 15 character positions each** (margin 75-ish for a typical terminal). **bas55 uses 16-character zones.** Most ECMA-55 test material assumes the **15-column, 5-zone** layout — but because it's implementation-defined, a conformance suite that pins exact column positions is testing an implementation choice, not the normative standard. **Flag: choose 15-wide zones to match the common reference behavior unless told otherwise.**
- **`,`** moves to the next zone start (or wraps to a new line if in the last zone). **`;`** abuts (null string). The **margin `m`** is the implementation-defined max characters per physical line (excluding end-of-line); TAB and zone-wrapping use it.

---

## 6. Expressions, operators, functions (clauses 8, 9)

### 6.1 Grammar and precedence (clause 8)
```
numeric-expression = sign? term (sign term)*          ' sign = + | -
term               = factor (multiplier factor)*       ' multiplier = * | /
factor             = primary (^ primary)*              ' ^ = circumflex (exponentiation)
primary            = numeric-variable | numeric-rep | numeric-function-ref
                   | ( numeric-expression )
```
**Precedence, highest → lowest:**
1. **`^` exponentiation** (involution)
2. **unary minus / unary plus** (a leading `sign` on a term)
3. **`*` and `/`** (equal precedence, left-to-right)
4. **`+` and `-`** binary (equal precedence, left-to-right)

**Associativity (verbatim rules, clause 8.4):**
- `A-B-C` = `(A-B)-C` (subtraction left-assoc)
- `A/B/C` = `(A/B)/C` (division left-assoc)
- **`A^B^C` = `(A^B)^C`** — exponentiation is **LEFT-associative** in ECMA-55 (NOT right-assoc like math/most languages!). **Flag this — it is a common conformance trap.**
- **`-A^B` = `-(A^B)`** — unary minus binds *looser* than `^`.

Order of evaluation summary (8.4): "involutions first, then multiplications and divisions, finally additions and subtractions."

**Special arithmetic cases (8.4):** `0^0 = 1` (by definition).

### 6.2 Relational expressions (clause 8 / 12)
`numeric-expr relation numeric-expr` with relations `= < > <= >= <>`; string comparisons only `=`/`<>`. Used in IF…THEN (not as general boolean values — Minimal BASIC has no boolean type/operators, no AND/OR/NOT).

### 6.3 Supplied (intrinsic) numeric functions (clause 9)
All take/return the single numeric type; trig in **radians**.

| Fn | Meaning | Notes / domain |
|----|---------|----------------|
| `ABS(x)` | absolute value | total |
| `SGN(x)` | sign: **−1 if x<0, 0 if x=0, +1 if x>0** | total |
| `INT(x)` | **floor** — largest integer ≤ x | `INT(1.3)=1`, `INT(-1.3)=-2` (rounds toward −∞) |
| `SQR(x)` | nonnegative square root | **x must be ≥ 0**; x<0 → **fatal** |
| `EXP(x)` | e^x (e≈2.71828) | if result < machine infinitesimal → 0; overflow → nonfatal (machine ∞) |
| `LOG(x)` | natural log | **x must be > 0**; x≤0 → **fatal** |
| `SIN(x)`,`COS(x)`,`TAN(x)` | trig, **x in radians** | TAN overflow → nonfatal (machine ∞) |
| `ATN(x)` | arctangent, result in radians | range `−π/2 < ATN(x) < π/2`; total |
| `RND` | next pseudo-random, **0 ≤ RND < 1**, uniform | **no argument**; see below |

- **`RND`** takes **no argument** in Minimal BASIC (`RND`, not `RND(x)`). Returns the next value in an implementation-supplied uniform pseudo-random sequence in `[0,1)`. 
  - **Without RANDOMIZE**: the sequence is **the same on every run** (reproducible). 
  - **`RANDOMIZE`** (clause 20) reseeds to an **unpredictable** start.
- **`INT` is floor (toward −∞)**, not truncation toward zero — `INT(-1.3) = -2`. Important.

### 6.4 Arithmetic exceptions (clause 8.5) — recovery values
| Condition | Class | Recovery |
|-----------|-------|----------|
| Division by zero | **nonfatal** | machine infinity, sign of numerator |
| Overflow | **nonfatal** | machine infinity, algebraically correct sign |
| **Underflow** | (handled silently) | result replaced by **0** |
| Negative base ^ non-integer exponent | **fatal** | — |
| Zero ^ negative exponent | **nonfatal** | **positive** machine infinity |

---

## 7. Exceptions defined by the standard (consolidated) — clause 3.5 framework

**Definitions (clause 3.5):** An **exception** arises from faulty data/computation or exceeding a resource constraint.
- **Nonfatal exception**: a recovery procedure is specified; if the implementation can follow it, execution continues (typically after substituting machine infinity / re-requesting input). Implementations must still **report** the exception (diagnostics).
- **Fatal exception**: no recovery procedure given (or hardware can't follow one) → **terminate the program**.

| Exception | Where | Class | Standard's action |
|-----------|-------|-------|-------------------|
| Division by zero | expr | nonfatal | machine ∞, sign of numerator |
| Arithmetic overflow | expr | nonfatal | machine ∞, correct sign |
| Underflow | expr | — | → 0 (silent) |
| Neg base ^ non-integer power | `^` | **fatal** | terminate |
| Zero ^ negative power | `^` | nonfatal | +machine ∞ |
| `LOG(x)`, x ≤ 0 | fn | **fatal** | terminate |
| `SQR(x)`, x < 0 | fn | **fatal** | terminate |
| `EXP`/`TAN` overflow | fn | nonfatal | machine ∞, correct sign |
| Subscript out of declared/default range | array | **fatal** | terminate |
| RETURN with no matching GOSUB | ctrl | **fatal** | terminate |
| ON…GOTO index < 1 or > list length | ctrl | **fatal** | terminate |
| READ past end of DATA (out of data) | READ | **fatal** | terminate |
| READ string datum into numeric var | READ | **fatal** | terminate |
| READ numeric overflow on datum | READ | nonfatal | machine ∞, signed, continue |
| READ/LET string datum > 18 chars | READ/LET | **fatal** | terminate |
| INPUT type mismatch | INPUT | nonfatal | re-request whole reply |
| INPUT too few data | INPUT | nonfatal | re-request |
| INPUT too many data | INPUT | nonfatal | re-request |
| INPUT numeric overflow | INPUT | nonfatal | re-request |
| INPUT string datum > 18 chars | INPUT | nonfatal | re-request |
| TAB argument < 1 | PRINT | (exception) | — |

**Notes / things the standard does NOT pin down:**
- **Reference to a nonexistent line number** (in GOTO/GOSUB/IF…THEN/ON…GOTO): the standard *requires* (12.4) that "all line-numbers in control-statements shall refer to lines in the program," but does NOT list it as a runtime exception or specify compile-vs-runtime detection. In practice it's a **program error detected before/at run** (most implementations reject at load/compile). **Flag: implementation-defined detection point.**
- **Uninitialized variable**: initial values are implementation-defined (7.4); reading one is **not** a defined exception (7.6 only *recommends* explicit init). Many implementations default numerics to 0 and strings to empty, but that is not guaranteed by the standard.

---

## 8. Execution model

- **Sequential**: execution begins at the **lowest-numbered line** and proceeds to successively higher-numbered lines, except where a control statement (GOTO/GOSUB/RETURN/ON…GOTO/IF…THEN/FOR…NEXT) transfers control.
- **DATA, REM, DIM, OPTION, DEF lines** are (for execution-flow purposes) effectively no-ops when reached: DATA/REM do nothing; DIM/OPTION/DEF are declarative (DEF's body isn't evaluated until called). Reaching such a line just proceeds to the next line.
- **Program termination** occurs on: reaching **END** (the last line), executing **STOP**, or a **fatal exception**. On normal/STOP/END termination, the program ends cleanly. (A "RUN" command — driving the program — is an implementation/system concern, not part of the program language proper; ECMA-55 specifies the program text and its semantics, not an interactive command set.)
- **Reaching the physical end without END is impossible** by construction, since END must be the last line; there is no "fall off the end" case.

---

## 9. Things to flag for our implementation (ambiguities / implementation-defined / reproduction agreement)

1. **Implementation-defined parameters** (must be chosen): numeric precision (≥6 sig digits — choose; we'll likely use our native float), range (≥1E±38), `d` (sig-width, ≥6), `e` (exrad-width, ≥2), print-zone width (≥ d+e+6) and zone count, the margin `m`, the input prompt string, the end-of-line indicator, and RND's sequence + RANDOMIZE seeding.
2. **Conventional concrete choices** (for matching common ECMA-55 behavior / test suites): **d=6**, **5 zones × 15 cols**, prompt `"? "`. **bas55** instead uses **d up to 8, 16-col zones, IEEE double** — so bas55's *exact* numeric columns differ from the d=6 reference. **Reproductions agree on the rules; they differ only in these implementation-defined numbers.** Decide which target to match before writing format tests.
3. **Exponentiation is LEFT-associative** (`A^B^C = (A^B)^C`) and **unary minus binds looser than `^`** (`-A^B = -(A^B)`). Both are common bug sources.
4. **`INT` is floor toward −∞**, not truncation.
5. **`RND` has no argument**; default sequence is reproducible; RANDOMIZE makes it unpredictable.
6. **No string ops beyond `=`/`<>` compare, assign, print, input/read.** No concat, no string functions, no string arrays, 18-char cap.
7. **Nonexistent-line detection point** is unspecified by the standard (we may detect at load time).
8. **Scaled-form trailing-zero elision** (`1.E-7` vs `1.00000E-07`) is within standard latitude; pin a choice and test it.
9. The **official ECMA PDF** is the final authority; this digest is built from a faithful plain-text reproduction cross-checked against an HTML reproduction and bas55. No substantive disagreements were found between reproductions on the *rules* — only on the implementation-defined *values* noted above.

---
*Digest completeness: covers all of clauses 3–23 at implementer grade (program format; data/value model incl. exact string scope; full statement set with syntax+semantics; expressions/precedence/associativity; all 11 intrinsic functions with domains; the full numeric output format with the d=6 threshold example; the complete exception table with fatal/nonfatal classification and recovery; execution model). Remaining gaps are only the implementation-defined numeric values, which the standard intentionally leaves open (flagged in §9).*
