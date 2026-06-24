# generics

Demonstrates Binate's **generics** — type parameters with interface-constraint
bounds, monomorphized — through three small library pieces the language
deliberately leaves out: a growable **`Vec`**, a **`Map`**, and a generic
**`Sort`**. They ultimately belong in the standard library; this is a teaching
example.

```
generics/
  pkg/vec.bni        Vec[T any] — growable array (the missing `append`)
  pkg/hashmap.bni    Map[K Hashable, V any] — open-addressing hash map
  pkg/sort.bni       Sort[T Orderable], IsSorted[T Orderable]
  cmd/demo/main.bn   collect in a Vec, Sort it, tally in a Map
  tests/run.sh       end-to-end fixture (both modes)
```

## What it shows

- **Generic structs + free functions.** Binate has no methods on generic types,
  so `Vec[T]` and `Map[K,V]` are structs operated on by free functions
  (`vec.Push[int](v, x)`, `hashmap.Put[int,int](m, k, val)`). Type arguments are
  always explicit — Binate does no inference.
- **Constraint bounds + method dispatch.** `Sort[T lang.Orderable]` and
  `Map[K lang.Hashable, V any]` bound their type parameters by stdlib interfaces;
  inside the bodies `a.Compare(b)` / `key.Hash()` dispatch to the concrete type's
  methods. Primitives satisfy these out of the box; a user type opts in with an
  `impl` (see the tests' `coord` / `keyed`).
- **`Hashable` gives hashing *and* equality.** `lang.Hashable` extends
  `lang.Comparable`, so a map key needs just that one bound — `Hash()` for the
  bucket, `Compare() == 0` for collision resolution.
- **Generic bodies live in the `.bni`** (template-in-header): a consumer
  monomorphizes each instantiation from the interface file, so the bodies — and
  the private generic helpers `Map` uses (`slotFor` / `grow`) — are there too.

## Run it

```sh
./scripts/run-compiled.sh    generics/cmd/demo
./scripts/run-interpreted.sh generics/cmd/demo   # byte-identical output
```

```
collected:
5
3
8
3
1
8
3
sorted:
1
3
3
3
5
8
8
occurrences of 3:
3
occurrences of 8:
2
distinct values:
4
```

The demo collects `5 3 8 3 1 8 3` in a `Vec`, sorts it in place through its
backing view, then tallies occurrences in a `Map` (`3` → 3, `8` → 2; 4 distinct
values) — all three packages composed.

## Tests

```sh
./scripts/run-tests-compiled.sh generics/pkg/vec
./scripts/run-tests-compiled.sh generics/pkg/hashmap
./scripts/run-tests-compiled.sh generics/pkg/sort
generics/tests/run.sh                             # end-to-end, both modes
```
