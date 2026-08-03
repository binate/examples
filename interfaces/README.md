# interfaces — nominal dispatch, and getting the value back out

Two shapes behind one interface, a third shape the library has never heard of,
and an inspector that takes values apart again.

## An `impl` is what satisfies an interface

Binate interfaces are **nominal**. Having the right methods is never enough —
`impl T : I` is the thing that makes `T` an `I`, and there is no structural
fallback:

```binate
func (r *readonly Rect) Area() float64          { … }
func (r *readonly Rect) Name() @[]readonly char { … }
impl *readonly Rect : Shape                      // without this line, not a Shape
```

`pkg/shape` ships a `Label` to make the point concrete: it has exactly `Shape`'s
method set — an `Area` and a `Name` — and deliberately no `impl`. Nothing rejects
it at compile time; it simply is not a Shape, and `Describe` finds that out at
run time:

```
label        a Label reading "not a shape", not a Shape
```

Note also *which* form is paired: it is `*readonly Rect` that satisfies Shape,
not `Rect`. The receiver form is part of the impl.

## There is no orphan rule

An `impl` may live in **any** package that can see both the type and the
interface. `cmd/demo` uses that: it declares its own `Triangle`, pairs it with
the library's `Shape`, and hands it back — and `pkg/shape`'s functions dispatch
to it without having been changed, including `Describe`, which recognizes it
through an interface-targeted assertion:

```
triangle     triangle of area 15
```

(Methods still belong to the type's own package. Only the `impl` travels.)

## `@Shape` owns, `*Shape` borrows

An interface value is spelled `*I` or `@I` — a bare `I` is not a value type — and
the two are built differently:

```binate
var owned @Shape = box(r)     // box copies r into a managed allocation
var view  *Shape = &r         // a borrow: a view of r itself
```

The difference is visible the moment the source changes:

```
borrow 12 and box 12; after widening the Rect: borrow 40, box 12
```

A `*Shape` is 2 words and tracks its source; an `@Shape` owns what it holds and
is what a collection wants, since a slice of borrows would outlive nothing safely.
That is why `shapes` here is `@[]@Shape` and each element is `box`ed.

An interface value is **never nil** — `present(v)` asks whether it was ever set,
which is what `Largest` of an empty slice returns.

## Getting the concrete value back

An assertion carries a mandatory **recovery kind**, and it is not decoration:

| form | meaning |
|---|---|
| `v.(T)` | copy the value out |
| `v.(*T)` | borrow it — a view that tracks the source |
| `v.(@T)` | retain it (needs an owning source) |

```
assertions: copy ok true (10x4), borrow ok true
after mutating: the borrow sees 99, the copy still 10
```

Always the **comma-ok** form unless a miss should be fatal: the bare `v.(T)`
aborts on a wrong guess, and there is no `recover` in the language.

A `switch x := v.(type)` recovers by cases, and scalars, text, and structs all
come back by value. `Describe` asks the interface question first and falls back
to the switch, which is the shape most real inspectors want: *behavior* if you
can get it, *representation* if you cannot.

## Identity: `same`, not `==`

Interface values (like slices and function values) **never compare with `==`**.
`same(a, b)` asks the only question that makes sense — do these refer to the same
thing:

```
identity: same(v, alias) true, same(v, other) false, same(v, v) true
```

## Layout

```
pkg/shape.bni + shape/     Shape, Rect, Circle, Label, TotalArea, Largest, Describe
pkg/shape/shape_test.bn    8 tests, including a shape declared in the test file
cmd/demo/                  the tour, plus a Triangle impl'd in the command
tests/                     compiled == interpreted == fixture
```

The test file declaring its own `square` and the command declaring its own
`Triangle` are the same check from two directions: dispatch must reach a type the
library's code never mentions.

## Building and running

```sh
interfaces/tests/run.sh                         # compiled == interpreted == fixture
scripts/run-compiled.sh          interfaces/cmd/demo
scripts/run-interpreted.sh       interfaces/cmd/demo
scripts/run-tests-compiled.sh    interfaces/pkg/shape
scripts/run-tests-interpreted.sh interfaces/pkg/shape
```

Dispatch is where two backends could most easily disagree — the compiler resolves
through a vtable it lays out, the VM through one it builds at load time — so the
two-mode diff is a real check here, not a formality.
