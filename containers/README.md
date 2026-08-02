# containers — the standard library's containers

A word counter built on `pkg/stdx/containers`: the growable **`Vec[T]`**, the
hash **`Map[K, V]`**, and the hash **`Set[T]`**, plus the iteration protocol they
share. Unlike [`generics`](../generics/), which *writes* generic containers as a
teaching exercise, this one *uses* the library's.

Binate has no built-in `map` and no `append` — growable collections are a library
concern, and these are the library's answer.

## Keying on text: why `Word` exists

The first thing anyone tries is a map keyed on a string, and it does not compile:

```binate
var m @hashmap.Map[@[]char, int] = hashmap.New[@[]char, int]()   // no
```

`Map[K lang.Hashable, V]` needs its key to implement `lang.Hashable`, and only the
scalar primitives do — no slice, pointer, or struct implements it. So text is
keyed through a one-field wrapper that supplies the two methods:

```binate
type Word struct { Text @[]readonly char }

func (w Word) Hash() uint            { … }   // FNV-1a over the bytes
func (w Word) Compare(other Word) int { … }  // 0 means equal
impl Word : lang.Hashable
```

Three things about that are worth pausing on:

- **The `impl` is required.** Declaring `Hash` and `Compare` is not enough —
  impls are nominal, so without the `impl` line `Word` does not satisfy the
  constraint no matter how well its method set matches.
- **Value receivers.** The constraint's `Self` is the value type, so the methods
  take `Word`, not `*Word`, and the impl names `Word`.
- **`Hash` must agree with `Compare`.** Equal words have to hash equally, or a
  lookup can miss a key that is present. Here both read the same normalized
  bytes, so they agree by construction; `TestHashAgreesWithCompare` pins it.

A `Word` **owns** its text (`@[]readonly char`, copied by `NewWord`) rather than
borrowing it. A map holds its keys indefinitely, so a borrow of the buffer the
word was split out of would dangle — `TestWordOwnsItsText` is exactly that
property.

## Which orders are guaranteed

A `Vec` iterates in index order. A `Map` and a `Set` iterate in **unspecified**
order — so the report walks a first-appearance `Vec` and looks each word up,
rather than walking the map. Printing map order into a fixture would be a test
that happens to pass.

Walking the map is still right for an order-independent question, and the demo
does that too (summing every entry's value and checking it equals the token
count). When a *stable* view of a set is wanted, `Has` answers membership without
iterating at all: the demo scans `1..8` and prints the lengths that are present.

## Cursors, and the boxed iterator

Every container follows one convention: `c.Iter()` returns a **value cursor**
whose `Next()` yields `(elem, true)` until exhaustion, then `(zero, false)`.

```binate
var it vec.Cursor[Word] = words.Iter()
for {
    w, ok := it.Next()
    if !ok { break }
    …
}
```

That cursor is concrete and monomorphized — `Next` is a direct call. The
alternative is `c.AsIterator()`, which boxes a cursor as `@iter.Iterator[T]`, an
interface value. It costs an allocation and a dynamic dispatch per element, and
it buys this: one **non-generic** function walks any container.

```binate
func Sum(it @iter.Iterator[int]) int    // fed by a Vec[int] AND a Set[int]
```

## Vec growth, and the contrast with `slices.Append`

`Vec.Push` doubles the backing from a 4-element floor, so a run of pushes is
amortized O(1); `Cap()` shows the doubling and `Items()` returns a view over the
live elements (writing through it writes into the Vec, and it goes stale — never
dangling — once a Push grows the backing).

`stdx/slices.Append` is the other way to grow a sequence, and the contrast is the
point: it allocates a fresh backing and copies **every** element on **every**
call, so the same loop is O(n²). It is the right tool for the occasional append,
not for building up a collection.

## Layout

```
pkg/tally.bni       Word (+ its lang.Hashable impl), Split, FirstSeen, Lengths, Sum
pkg/tally/          the bodies, and the unit tests
cmd/wordcount/      the demo: counts, lookups, iteration, Vec growth
tests/              the compiled == interpreted == fixture harness
```

The counting itself lives in `cmd/wordcount` rather than in `pkg/tally`, which is
**not** a design choice: a `.bni` currently cannot name a generic instantiated on
a type its own package `impl`s, so declaring

```binate
func Counts(words @vec.Vec[Word]) @hashmap.Map[Word, int]
```

is rejected with `type argument Word does not satisfy constraint Hashable` — with
the `impl` a few lines below in the same file. Any `.bn` builds that map happily
(the command does, and so do this package's tests), and so does another package's
`.bni`; only the declaring package's own interface file trips. See
[`TODO.md`](../TODO.md).

## Building and running

```sh
containers/tests/run.sh                     # compiled == interpreted == fixture
scripts/run-compiled.sh          containers/cmd/wordcount
scripts/run-interpreted.sh       containers/cmd/wordcount
scripts/run-tests-compiled.sh    containers/pkg/tally
scripts/run-tests-interpreted.sh containers/pkg/tally
```

Expected output is pinned in [`tests/expected.txt`](tests/expected.txt).
