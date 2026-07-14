# variadics — variadic functions and spread

A small aggregation library and a demo that exercise Binate's **variadic
functions** (`func f(xs ...T)`) and the **spread** operator (`slice...`).

Binate variadics are **homogeneous** — a variadic parameter has one element type
`T`, so `Sum(1, 2, 3)` takes `...int`, not an arbitrary mix of types (there is no
`printf(fmt, ...)`-style heterogeneous variadic; `print`/`println` are separate
predeclared forms). Key properties this example shows:

- **Zero heap allocation.** Individual arguments (`Sum(1, 2, 3)`) are packed into
  a caller-side stack array; the callee sees a raw slice `*[]T` — a *borrow*,
  valid only for the call. To keep the values a callee copies them into owned
  storage; these read-only aggregators don't.
- **Spread forwards a slice.** `Sum(xs...)` passes an existing slice's
  `{data, len}` directly — no per-element copy. A managed-slice `@[]T` decays; an
  array must be sub-sliced first (`arr[:]...`).
- **Last parameter only.** At most one variadic parameter, and it must be last;
  `Max(first int, rest ...int)` shows a fixed parameter before it.
- **Part of the type.** Variadic-ness is part of a function's type, so
  `*func(...int) int` is a distinct variadic function-value type, and generic
  functions carry it through monomorphization (`Count[T](xs ...T)`).

Unlike [`cinterop`](../cinterop/), variadics are an ordinary language feature
(not FFI), so everything here runs **both compiled and interpreted**, has unit
tests that run under both backends, and its e2e asserts the two modes agree.

## The library

[`pkg/agg`](pkg/agg.bni) — variadic aggregators:

| function                                              | shows                              |
|-------------------------------------------------------|------------------------------------|
| `Sum(xs ...int) int`                                  | basic variadic; empty case         |
| `Max(first int, rest ...int) int` / `Min(...)`        | fixed parameter before variadic    |
| `Fold(init int, combine *func(int,int) int, xs ...int)` | variadic + a function-value combiner |
| `Count[T any](xs ...T) int`                           | generic variadic, any element type |
| `FirstOr[T any](dflt T, xs ...T) T`                   | generic variadic + fixed default   |

`Count`/`FirstOr` are generic, so (per Binate's template-in-header
monomorphization) their bodies live in the `.bni`; the non-generic bodies are in
`pkg/agg/agg.bn`.

## The demo

[`cmd/demo`](cmd/demo/main.bn) composes all the call shapes. Expected output
(pinned in [`tests/expected.txt`](tests/expected.txt)):

```
10      Sum(1,2,3,4)
0       Sum()                 (empty)
9       Max(3,1,4,1,5,9,2)    (fixed + variadic)
1       Min(3,1,4,1,5,9,2)
50      Sum(nums...)          (spread a managed-slice)
12      Sum(arr[:]...)        (spread an array sub-slice)
10      Fold(0, add, 1..4)    (function-value combiner)
24      Fold(1, mul, 1..4)
60      total(10,20,30)       (variadic function value)
5       Count[int](1..5)      (generic variadic)
3       Count[char]('x','y','z')
7       FirstOr[int](99, 7, 8)
99      FirstOr[int](99)      (empty -> default)
```

(The numeric column is the actual output; the right column is annotation.)

## Building and running

```sh
variadics/tests/run.sh          # compiled == interpreted == fixture
scripts/run-compiled.sh    variadics/cmd/demo
scripts/run-interpreted.sh variadics/cmd/demo
scripts/test-all.sh both variadics/pkg/agg
```

Variadics shipped in `bnc-0.0.11`, so this example builds and runs with the
pinned toolchain — no special setup.
