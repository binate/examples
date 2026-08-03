# math — floating point, and integers that do not overflow

Two runnables over `pkg/std/math` and `pkg/std/math/big`, on either side of one
question: what happens when a number does not fit?

- [`cmd/floats`](cmd/floats/main.bn) — IEEE 754 float64: the classes, NaN,
  signed zero, the five ways to round, saturating conversion, and where
  precision runs out.
- [`cmd/bignat`](cmd/bignat/main.bn) — `big.Nat`, an arbitrary-precision
  unsigned integer, which is what you reach for once it has.

## Everything is defined

Binate has no undefined behavior in arithmetic and no trapping modes. Every
operation below produces a value:

| operation | result |
|---|---|
| integer overflow | wraps (`int64` max + 1 is `int64` min) |
| `float64` → `int64` past the range | saturates at the extreme |
| `NaN` → `int64` | `0` |
| `inf - inf`, `inf * 0` | `NaN` |
| `1.0 / 0.0` | `+Inf` (integer `/ 0` panics — that one is a fault) |

Defined is not the same as lossless, which is why `fp.ToInt64` returns a second
result: the conversion always produces *something*, and the bool is the only way
to tell a genuine `9223372036854775807` from a saturated one.

## The two zeros and the value that is not itself

`-0.0 == 0.0` is true and their bit patterns differ, so equality is not identity
here. The sign survives arithmetic and is observable — `Signbit`, and `1/x`
giving `-Inf` rather than `+Inf` — which is why `fp.Class` reports `zero` and
`-zero` separately.

NaN is the other way around: it compares **false** against everything, itself
included. That is not a quirk to route around; `x != x` is the NaN test, and
`math.IsNaN` is its name.

> The example builds its negative zero with `math.Copysign(0.0, -1.0)` rather
> than writing `-0.0`. That is the portable spelling regardless — Go folds a
> `-0.0` literal to `+0.0`, so Copysign is how you write one there too — but here
> it is also load-bearing: the bytecode VM currently computes `-x` as `0.0 - x`,
> which loses the sign of a zero, so the literal would make this program disagree
> with itself across the two modes. It is a tracked toolchain bug, and
> [`TODO.md`](../TODO.md) records what to change back once it is fixed.

## Five ways to drop a fraction

```
  x       floor   ceil  trunc  round   even
  2.5         2      3      2      3      2
  3.5         3      4      3      4      4
  -2.5       -3     -2     -2     -3     -2
```

`Round` goes away from zero at exactly .5; `RoundToEven` goes to the even
neighbour, which is what stops a long sum of rounded values from drifting
upward. `Trunc` and `Floor` differ only for negatives.

## Where precision ends

One **ulp** is the distance to the next representable value: about 2.2e-16 near
1.0, exactly 2.0 near 2^53. Once it exceeds 1, the float64 can no longer count —
`9007199254740993.0 == 9007199254740992.0` is *true*, and `0.1 + 0.2 == 0.3` is
false by 5.5e-17.

That is the handoff to the second program. `big.Nat` holds
`30414093201713378043612608166064768844377641568960512000000000000` (50!) and
`Fib(100)` exactly. `Fib(93)` still fits a `uint64` but has already passed the
`int64` maximum — which is where the machine-integer `Fib` in the
[`numbers`](../numbers/) example starts wrapping into nonsense.

## Reading a Nat, and the destination-first convention

`big` ships arithmetic but no text conversion, so `bigx.Decimal` is the missing
half: divide by 10 repeatedly, keep the remainders, reverse. It clones first,
because dividing consumes the destination and printing a number should not
destroy it.

The arithmetic follows Go's `math/big` convention — `z.Add(x, y)` sets `z` and
returns it, and `z` may alias an operand. That is what makes an accumulator loop
allocation-free:

```binate
acc = acc.MulUint32(acc, cast(uint32, k))    // acc *= k, in place
```

`DivMod` is the exception worth reading twice: its two destinations must be
distinct Nats, and passing one for both silently yields wrong results.

## Layout

```
pkg/fp.bni + fp/         Class, ToInt64, Ulp — the float64 helpers math leaves out
pkg/bigx.bni + bigx/     Decimal, Factorial, Fib over big.Nat
cmd/floats/              the IEEE tour
cmd/bignat/              the arbitrary-precision tour
tests/                   both runnables, compiled == interpreted == fixture
```

The two-mode diff matters more here than anywhere else in this repo: floating
point is exactly where a compiler and an interpreter drift apart — a different
rounding mode, an 80-bit intermediate, a libm with its own `Pow`. `pkg/std/math`
is pure Binate with no libm underneath, and the fixtures are byte-identical
across both backends.

## Building and running

```sh
math/tests/run.sh                                # both runnables, both modes
scripts/run-compiled.sh          math/cmd/floats
scripts/run-interpreted.sh       math/cmd/bignat
scripts/run-tests-compiled.sh    math/pkg/fp
scripts/run-tests-interpreted.sh math/pkg/bigx
```
