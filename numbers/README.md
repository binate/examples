# numbers

Demonstrates an **example-local package** and **two runnables sharing it**.

```
numbers/
  pkg/seq.bni             interface: Fib, Gcd
  pkg/seq/seq.bn          implementation
  pkg/seq/seq_test.bn     unit tests
  cmd/fib/main.bn         runnable — prints Fib(0..10)
  cmd/gcd/main.bn         runnable — prints two GCDs
  tests/                  end-to-end: both runnables, both modes
```

`pkg/seq` is private to this example. It resolves as `import "pkg/seq"` because
`numbers/` is the example's package search root (prepended to the toolchain's
`-I`/`-L` paths). Both `cmd/fib` and `cmd/gcd` import the same `pkg/seq`.

Run them (from the repo root):

```sh
./scripts/run-compiled.sh    numbers/cmd/fib   # 0 1 1 2 3 5 8 13 21 34 55
./scripts/run-interpreted.sh numbers/cmd/gcd   # 12, then 21
```

The split between the two kinds of test follows the split in the layout: the unit
tests check `pkg/seq` itself (the base cases, the recurrence, and — since Euclid
is easy to get subtly wrong — that the result really is the *greatest* common
divisor over a small grid), while the harness pins what each runnable prints.

```sh
./scripts/run-tests-compiled.sh    numbers/pkg/seq
./scripts/run-tests-interpreted.sh numbers/pkg/seq
numbers/tests/run.sh               # both runnables, compiled == interpreted == fixture
```
