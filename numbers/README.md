# numbers

Demonstrates an **example-local package** and **two runnables sharing it**.

```
numbers/
  pkg/seq.bni        interface: Fib, Gcd
  pkg/seq/seq.bn     implementation
  cmd/fib/main.bn    runnable — prints Fib(0..10)
  cmd/gcd/main.bn    runnable — prints two GCDs
```

`pkg/seq` is private to this example. It resolves as `import "pkg/seq"` because
`numbers/` is the example's package search root (prepended to the toolchain's
`-I`/`-L` paths). Both `cmd/fib` and `cmd/gcd` import the same `pkg/seq`.

Run them (from the repo root):

```sh
./scripts/run-compiled.sh    numbers/cmd/fib   # 0 1 1 2 3 5 8 13 21 34 55
./scripts/run-interpreted.sh numbers/cmd/gcd   # 12, then 21
```
