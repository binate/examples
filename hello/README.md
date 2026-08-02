# hello

The minimal Binate example: print a line and exit. A single runnable,
`cmd/hello/main.bn` (`package "main"`), with no packages of its own.

Run it (from the repo root):

```sh
./scripts/run-compiled.sh    hello/cmd/hello
./scripts/run-interpreted.sh hello/cmd/hello
```

Output:

```
Hello from Binate!
```

There is nothing here to unit-test, but the output is still pinned:

```sh
hello/tests/run.sh    # compiled == interpreted == fixture
```

That is worth having precisely because the program is trivial — it makes this the
first thing to fail if the toolchain stops building, linking, or interpreting the
smallest program there is.
