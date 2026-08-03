# text — building and parsing text

Binate has **no string type**. Text is `@[]readonly char` — a slice of bytes,
since `char` *is* `uint8` — and there is no `+` to join two of them. So the
standard library's answer comes in two pieces: `pkg/std/strconv` converts between
values and their text, and `pkg/std/strings.Builder` accumulates text without
quadratic copying.

`pkg/csv` here parses and renders a deliberately tiny record format,
`name,count,ratio`, which is enough to need both.

## Two families in strconv, and the difference is allocation

```binate
strconv.Itoa(42)                        // @[]char — allocates, caller owns
strconv.AppendInt(dst, pos, 42, 10)     // int — writes into YOUR buffer
```

`Format*`/`Itoa` are the convenient half. `Append*` is the half for a loop that
would otherwise allocate per value: it writes at a position in a caller-owned
buffer and returns where the next append would start, so a whole record — or a
whole table — lands in one buffer with no intermediates.

The price is an overflow contract, and it is worth learning because it is
unusual: when the buffer is too small, **nothing is written** and the result is
**negative**, its magnitude being a length that would suffice. So a caller sizes
a buffer by trying:

```
append into 4 bytes: -69 (negative means it did not fit)
retry with 69 bytes: wrote 11 -> [alpha,3,0.5]
```

`csv.AppendRecord` propagates that same contract rather than inventing its own,
and its test checks the part that makes it usable: after a failed call the
buffer is untouched, and a retry at the reported size succeeds.

## Parsing reports failure two ways at once

`Parse*` returns a value *and* an error, and on overflow both are meaningful: the
value **saturates** at the type's extreme and the error says it was out of range.

```
overflow: int64 9223372036854775807 (err true), int8 127 (err true)
```

Base 0 infers from the prefix (`0x2a`, `0o52`, `0b101010`) and accepts `_`
separators. `ParseFloat` accepts the specials (`inf`, `nan`) and hex floats.

One thing to know: **strconv's errors root in no base**, so
`errors.Is(err, errors.BadData)` is false for a syntax error. That is a tracked
gap in the library, not a design choice — which is why `csv.Parse` re-roots what
it gets, quoting strconv's message (it names the field and the reason) under its
own `errors.BadData`:

```
[alpha,three,0.5] -> count: strconv.Atoi: parsing "three": invalid syntax (BadData true)
```

## Floats round-trip, if you ask for it

`FormatFloat(f, 'g', -1, 64)` — precision **-1** — emits the shortest text that
reads back as *bit-identical*. That is what makes `ParseAll(Render(rs))` return
`rs` even for `1.0/3.0`, and it is why the rendered form of `1e-9` is `1e-09`
rather than a longer exact decimal. A fixed precision (`'f', 6`) is for display;
`-1` is for anything that will be read again.

## Builder: one backing, grown exponentially

`strings.Builder` owns its bytes and doubles as needed, so appending in a loop
stays amortized O(1). Two properties are worth seeing:

- **`String()` does not copy.** It returns a view of the Builder's own backing.
- **A string handed out earlier survives `Reset`.** The Builder drops its
  backing, but that earlier result kept its own reference to those bytes:

```
after Reset: len 8 text [replaced], earlier string still [abc!]
```

A `*Builder` is an `io.Writer` and an `io.ByteWriter`, so anything that writes
bytes — including `fmt.Fprintf` — can write into one.

## Views, and what a parsed record owns

`csv.Parse` fills `Record.Name` with a **sub-slice of the line**, not a copy. A
managed sub-slice retains the whole backing, so this is safe — never a dangling
view — but it does keep the entire line alive for as long as any record cut from
it. That is the trade the [`containers`](../containers/) example makes the other
way, where `Word` copies its text because a map holds keys indefinitely.

## Layout

```
pkg/csv.bni + csv/     Record, Parse, ParseAll, Render, AppendRecord
pkg/csv/csv_test.bn    6 tests, including the append contract and a float round trip
cmd/records/           the tour: parse, render, append, and Builder mechanics
tests/                 compiled == interpreted == fixture
```

## Building and running

```sh
text/tests/run.sh                               # compiled == interpreted == fixture
scripts/run-compiled.sh          text/cmd/records
scripts/run-interpreted.sh       text/cmd/records
scripts/run-tests-compiled.sh    text/pkg/csv
scripts/run-tests-interpreted.sh text/pkg/csv
```

The fixture is mostly rendered numbers, which makes the two-mode diff a real
check: shortest-round-trip float formatting and saturating integer parsing have
to produce identical text in both backends.
