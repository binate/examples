# generics

Demonstrates Binate's **generics** — type parameters with interface-constraint
bounds, monomorphized — through a small generic `sort`. Containers and sorts
like this ultimately belong in the standard library; this is a teaching example.

```
generics/
  pkg/sort.bni        Sort[T Orderable], IsSorted[T Orderable]
  cmd/demo/main.bn    sorts ints and a user Orderable type
  tests/run.sh        end-to-end fixture (both modes)
```

## What it shows

- **Generic functions with a constraint.** `Sort[T lang.Orderable](s @[]T)` works
  for any element type satisfying `lang.Orderable` (a total order via `Compare`).
  Type arguments are always explicit — `Sort[int](nums)` — Binate does no
  inference.
- **Constraint-method dispatch.** Inside the generic body `s[i].Compare(s[j])`
  calls through the constraint interface; each instantiation resolves it to the
  concrete type's method.
- **Primitives satisfy the standard constraints.** `int`, `uint`, `uint8`, … ship
  with `impl … : lang.Orderable` in `pkg/builtins/lang`, so `Sort[int]` just
  works.
- **User types opt in** with one declaration (`cmd/demo`'s `record`):
  ```
  func (r record) Compare(other record) int { return r.score - other.score }
  impl record : lang.Orderable
  ```
- **Generic bodies live in the `.bni`.** A consumer monomorphizes `Sort[T]` at
  its own call site, so the body is in `pkg/sort.bni` rather than a `.bn` — the
  template-in-header model.

## Run it

```sh
./scripts/run-compiled.sh    generics/cmd/demo
./scripts/run-interpreted.sh generics/cmd/demo   # byte-identical output
```

```
unsorted ints:
5
3
8
1
9
2
7
sorted ints:
1
2
3
5
7
8
9
record ids, sorted by ascending score:
4
2
5
3
1
```

(The records carried scores 50, 20, 40, 10, 30; ascending by score gives ids
4, 2, 5, 3, 1.)

## Tests

```sh
./scripts/run-tests-compiled.sh generics/pkg/sort   # the generic sort
generics/tests/run.sh                               # end-to-end, both modes
```

## Why only `sort`?

This example was meant to also carry a generic growable `Vec[T]` and a
`Map[K, V]`. Both are currently blocked by toolchain limitations in generic
instantiation that `sort` happens to avoid — it is generic only over `@[]T`
(never a user generic struct) and is a single self-contained function:

- a generic function can't take or return a generic struct instantiated with its
  own type parameter (so `func Push[T any](v @Vec[T], x T)` is rejected); and
- a constrained generic can't forward its type parameter to another constrained
  generic (so a factored `Sort → partition → swap` is rejected).

Both are filed in the binate repo's `explorations/claude-todo.md`. `vec` and
`hashmap` land here once they are fixed — see [`../TODO.md`](../TODO.md).
