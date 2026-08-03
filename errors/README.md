# errors — errors as values

Binate has no exceptions. A function that can fail returns the failure as its
last result, and the caller decides what to do with it. This example is a small
`key = value` config parser that fails four different ways, and a program that
shows what a caller can actually *do* with each one.

> **This example is compiled-only for now, and sits out the default sweeps.**
> `bni` segfaults on `errors.Is` when the error's dynamic type is a user-defined
> `errors.Error` — which `ParseError` below is. It is a tracked MAJOR toolchain
> bug, reproduced on the pinned `bnc-0.0.12` and on a `main` build; the same code
> compiled is correct throughout. See [`.skip-default-sweeps`](.skip-default-sweeps).

## There is no nil to compare against

An interface value is never nil, so the test is `present`:

```binate
cfg, err := config.Parse(text)
if present(err) { … }
```

## Three ways to produce a failure, and they are not interchangeable

**Wrap** adds context and keeps the cause — including its classification.
`Load` wraps whatever `os.Open` returned, so `errors.Is(err, errors.NotFound)`
still holds for a missing file, and the message reads
`reading /etc/app.conf: open: not found`.

**Root** mints a *new* error under a chosen base. That is how you re-classify:
with a single `Unwrap` link a wrapper inherits its cause's classification, so an
error that needs a different one is minted fresh (the cause survives in the
message). `Parse` roots a bad value in `errors.BadData` this way.

**A concrete type** carries structured data a message cannot. `ParseError` holds
the line number as a field:

```binate
type ParseError struct {
    Line   int
    Detail @[]readonly char
    base   @errors.Error
}

func (e @ParseError) Error() @[]readonly char { … }   // "line 4: unknown key \"colour\""
func (e @ParseError) Unwrap() @errors.Error   { … }   // the base it roots in
impl @ParseError : errors.Error
```

Returning the base from `Unwrap` is how a concrete type roots itself — exactly
what `errors.Rooted` does for the anonymous case. Note `Error()` returns
`@[]readonly char`, unlike `lang.Stringer`'s `String() @[]char`.

## Classify, don't parse messages

Every stdlib error roots in one of the standard bases, and `errors.Is` walks the
whole chain, so it finds a base through any amount of wrapping. The parser uses
the distinction deliberately:

| input                | classification              |
|----------------------|-----------------------------|
| a line with no `=`   | `BadData`                   |
| a value that won't parse | `BadData`               |
| an unrecognized key  | `InvalidArgument`           |
| no `name` key at all | `NotFound`                  |
| a missing file       | `NotFound` (from `os`, wrapped) |

`BadData` and `NotFound` both root in `ConditionsUnmet`, so a caller that only
cares about "the request was fine, the world wasn't" matches at that level.
`InvalidArgument` is a *different branch* — the request itself is wrong — and the
example checks that it does **not** match `ConditionsUnmet`.

## Recovering the structured error

A caller pulls the concrete type back out of an `@errors.Error` with a type
assertion, which carries a mandatory recovery kind — `@T` retains, `*T` borrows,
`T` copies:

```binate
pe, ok := err.(@config.ParseError)
if ok { fmt.Printf("line %d\n", pe.Line) }
```

Use the comma-ok form: the bare `err.(@T)` aborts on a miss, and there is no
`recover`. The demo asserts on the missing-`name` error too, which is *not* a
`ParseError` — and reports that rather than dying.

## Walking a chain

`Unwrap` exposes the cause, so the lineage is walkable. A wrapping error renders
its cause as well, so the messages shorten as the walk descends:

```
  0: [reading /definitely/not/here.conf: open: not found]
  1: [open: not found]
  2: [not found]
  3: [conditions unmet]
```

Layer 2 is the `NotFound` base itself and layer 3 its parent — the hierarchy is
just these same chains.

## Layout

```
pkg/config.bni + config/     Config, ParseError, Parse, Load
pkg/config/config_test.bn    10 tests over the classifications and the chain
cmd/report/                  one good parse and five failures
tests/                       compiled vs fixture (see the note above)
```

## Building and running

```sh
errors/tests/run.sh                            # compiled vs fixture
scripts/run-compiled.sh       errors/cmd/report
scripts/run-tests-compiled.sh errors/pkg/config
```

`scripts/run-interpreted.sh` and `run-tests-interpreted.sh` will crash the VM
until the bug above is fixed. Expected output is pinned in
[`tests/expected.txt`](tests/expected.txt).
