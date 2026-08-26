# fmt — formatted output

Every other example in this repo prints with `pkg/std/fmt`. This one is about it.

It opens with an aligned table, because the most useful thing `fmt` does here is
not a verb at all.

```
station  reading  trend
Ostrava      21C  rising
Kiruna       -8C  steady
Ushuaia       4C  falling
```

## A width can be an operand

Column widths are not known until every row is in, so they cannot be written into
a format string. `*` takes them from the argument list instead:

```binate
fmt.Fprintf(b, "%-*s", width, cell)    // left-aligned in `width` columns
fmt.Fprintf(b, "%*s", width, cell)     // right-aligned
```

That is all `pkg/table` is: collect rows, take the longest cell per column, then
render with the widths as operands. `.*` does the same for precision.

**A width is a byte count, not a column count.** Text is a slice of bytes, so
`"21°C"` measures 5 and displays 4 — which is why the table above stays ASCII,
and why `TestWidthCountsBytes` pins the behaviour rather than pretending.

## The operands fmt understands

Any scalar, the char-slice spellings, and — since `bnc-0.0.13` — a struct, by
reflection. `%v` prints the values; `%+v` names the fields; nested structs,
arrays and slices recurse:

```
%v  {Ostrava {21} [6 12 18] clear}
%+v {Station:Ostrava Temp:{Deg:21} Hours:[6 12 18] Notes:clear}
```

A **pointer operand is followed, not printed** — `fmt.Printf("%v", &r)` renders
what `r` renders. (A pointer *field* is the exception: it shows as `&{…}`, to say
the value was reached through one.)

A type with a `String()` method takes that path instead, for both `%v` and `%s`.
That is `lang.Stringer`, and joining in costs one method plus the `impl` line.

> The example's `String()` copies its result, which is worth knowing about:
> `lang.Stringer` requires `String() @[]char`, while `Sprintf` and
> `strings.Builder` both produce `@[]readonly char`. Dropping element-level
> `readonly` is not a `cast` — another live handle may rely on that view, so the
> language demands an explicit `unsafe_cast` — and copying is the honest way to
> satisfy the signature. It is a known wart in the interface, not in your code.

`%s` of a non-string is not an error, unlike Go: it renders the value's default
text, so `%s` of `42` is `42`.

## Nothing fails silently

A bad format never drops output — every mistake renders as a visible verb:

```
too few operands  [1 %!d(MISSING)]
wrong type        [%!d(string=not a number)]
a bad star width  [%!(BADWIDTH)1]
a trailing pct    [100%!(NOVERB)]
too many operands [1]
%!(EXTRA string=spare)
```

`EXTRA` is appended after the whole format has been rendered, which is why it
lands at the end rather than where a missing verb would have been.

## Destinations

`Print`/`Printf` go to standard output, `Sprint`/`Sprintf` return the text, and
`Fprint`/`Fprintf` take any `io.Writer` — a `strings.Builder` here, and
`os.Stderr` for the one line the demo sends there. The harness captures the two
streams separately and checks that line really did go to stderr.

`Sprint` inserts a space between two operands only when **neither** is a string
(`Sprint("a", 1, 2, "b")` → `a1 2b`); `Sprintln` always separates and appends a
newline.

## Layout

```
pkg/table.bni + table/     Table: rows in, aligned columns out
pkg/table/table_test.bn    7 tests, including the byte-width caveat
cmd/demo/                  the verb grid, reflection, Stringer, diagnostics
tests/                     compiled == interpreted == fixture
```

## Building and running

```sh
fmt/tests/run.sh                                # compiled == interpreted == fixture
scripts/run-compiled.sh          fmt/cmd/demo
scripts/run-interpreted.sh       fmt/cmd/demo
scripts/run-tests-compiled.sh    fmt/pkg/table
scripts/run-tests-interpreted.sh fmt/pkg/table
```

Formatting is exactly where two backends could drift — float rendering, padding
arithmetic, the reflection walk — so the two-mode diff earns its keep here.
