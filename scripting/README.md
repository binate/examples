# scripting — one file, three ways to run it

`cmd/greet/main.bn` is an ordinary Binate program with a `#!` line on top. It
runs directly through the kernel, through `bni`'s script mode, and as a compiled
binary — the same source, unmodified:

```sh
PATH=scripting/bin:$PATH  scripting/cmd/greet/main.bn world friend   # kernel
scripting/bin/bnrun scripting/cmd/greet/main.bn world friend         # bni -x
scripts/run-compiled.sh scripting/cmd/greet world friend             # bnc
```

```
argc 3
started from source: true
hello, world
hello, friend
```

## What the toolchain provides

Exactly one thing: **the lexer ignores a `#!` line at offset 0** (spec
`lex.shebang`), in `bnc` as well as `bni`. That is what lets a file be both a
script and a compilable program.

Plus `bni -x`, which is script *mode*: exactly one source file, and everything
after it belongs to the program rather than being taken as more sources or
interpreter flags.

## What the shebang cannot do, and why that is not Binate's problem

A `#!` line can name a fixed absolute path, or — via `/usr/bin/env` — something
on `PATH`. Both are deployment assumptions, and both are wrong for an uninstalled
tree like this repo:

- a fixed path assumes an installer ran;
- `/usr/bin/env bni` assumes `bni` is on `PATH` **and** that it can find its own
  standard library, which today it cannot: `bni` has no default search path, so
  even a zero-import script fails with `package "pkg/bootstrap" not found`;
- passing the search paths on the line is not an option either. They are 264 and
  353 characters for a cached bundle, against a kernel limit of about **256 bytes
  for the whole line** — and they differ per machine, so they could not be
  committed anyway.

This is the ordinary shebang problem — every interpreted language has it, which
is why `#!/usr/bin/env python3` exists and why virtualenvs rewrite shebangs on
install. The useful property is not "you can name the interpreter"; with `env`
you already are not. It is that you can name **anything**.

So this example names its own launcher:

```
#!/usr/bin/env bnrun
```

21 bytes, no absolute paths, nothing machine-specific. [`bin/bnrun`](bin/bnrun)
is a nine-line shell script that resolves the toolchain the same way the rest of
the repo does — honoring `BUILDER_VERSION` and `BINATE_BUNDLE` — and execs
`bni -x` with the search paths filled in. A real project would ship the same
thing, or install a `bni` that knows where its library lives.

One subtlety worth knowing: the kernel refuses a `#!` line whose interpreter is
*itself* a script. That rule does not bite here, because the interpreter is
`/usr/bin/env`, a binary — `env` then execs `bnrun` from user space, where a
shebang is resolved normally.

## argv[0] says how you were started

`os.Args()` element 0 is the program name, and it names whatever actually started
the program: the **script** path under `bni -x`, the **binary** path when
compiled. The program reports which kind it got, and that is the single line on
which the two fixtures differ — the harness checks that it is the *only* one.

```
started from source: true     # kernel exec, and bni -x
started from source: false    # compiled
```

## A wrinkle in printing arguments

The loop copies each argument into a local before printing it:

```binate
var arg @[]readonly char = args[i]
fmt.Printf("hello, %s\n", arg)
```

That is required, not stylistic. `os.Args()` is fully readonly — element slots
included — so an element has type `readonly @[]readonly char`, and `fmt` has no
case for a readonly-qualified slice: printing `args[i]` directly renders
`%!?(unknown)`. The copy is free (a slice is a handle, not the bytes) and the
same bytes then print fine. It is a tracked gap in `fmt`, recorded in
[`TODO.md`](../TODO.md) so the workaround comes back out when it is fixed.

## Layout

```
bin/bnrun            the launcher the #! line names
cmd/greet/main.bn    the script — also a normal cmd, so build-all compiles it
tests/               all three legs, against two fixtures
```

Keeping the script in `cmd/greet/` rather than a scripts directory is deliberate:
it is a normal runnable as far as the rest of the repo is concerned, so
`build-all.sh` compiles it and `run-compiled.sh` runs it, which is exactly the
claim the example is making.

## Building and running

```sh
scripting/tests/run.sh                       # all three legs
PATH=scripting/bin:$PATH scripting/cmd/greet/main.bn one two
scripting/bin/bnrun scripting/cmd/greet/main.bn one two
scripts/run-compiled.sh    scripting/cmd/greet one two
scripts/run-interpreted.sh scripting/cmd/greet one two
```

The exec bit on `cmd/greet/main.bn` is load-bearing — without it the kernel never
looks at the `#!` line — so the harness checks for it before anything else.
