# flags — parsing a command line

`pkg/stdx/flags` is the standard flag parser — the one `bni`'s own command line
is built on. This example is a small tool, `greet`, that uses it the way a real
tool does.

```
$ greet -v --name=Ada -c 2 -t x -t y -p one:two extra1 extra2
verbose true, name Ada, count 2
tags [x y]
paths [one two]
positionals [extra1 extra2]
hello, Ada!
hello, Ada!
```

## Destinations bind by pointer

There is no `Lookup("name")` afterwards. Each flag is bound to a field when it is
registered, and Parse fills that field in place:

```binate
fs.BoolVar(&opts.Verbose, "verbose", "v", "explain what is happening")
fs.StringVar(&opts.Name, "name", "n", "world", "who to greet")
fs.IntVar(&opts.Count, "count", "c", 1, "how many times to greet")
```

So a misspelled flag name is a *runtime* error in your argument vector, but a
misspelled **destination** is a compile error. The defaults are the values the
fields already hold.

## The grammar, and what it refuses

Dash-insensitive, so `-v`, `-verbose` and `--verbose` are the same flag. Values
come as `--name value` or `--name=value`, with the alias forms too. A bool never
consumes the next token: `-v later` sets verbose and leaves `later` alone.

Two things it deliberately does **not** do:

- **No bundling and no attached values** — `-abc` is not `-a -b -c`, and `-oX` is
  not `-o X`. This is Go's `flag` shape, not `getopt`.
- **No interspersing.** Parsing stops at the first positional, or at `--`:

```
$ greet -v file.txt -n Ada        # -n Ada are POSITIONALS, not flags
$ greet -v -- -n --tag            # -- ends the flags; both are operands
```

That rule is a safety property, not an ergonomic one: a shell glob that expands
to a file named `-n` cannot inject a flag into your program.

Repeatable flags collect (`-t x -t y`), and the separated variant splits as well
as repeats, so `-p one:two` and `-p one -p two` mean the same — which is how a
search path is spelled.

## Errors are values

Parse returns `(positionals, message)`. The message is empty on success and
ready to print otherwise; the library never prints and never exits. The command
decides:

```
$ greet --nope
greet: unknown flag: --nope
usage: greet [flags] [args]
  -h, --help    print this help and exit
  ...
$ echo $?
2
```

`-h` needs no special handling either — it is an ordinary bool flag, checked
before anything else.

## The seam worth knowing about

`ArgsToVector` copies, and it is not being careless:

```binate
var opts cli.Options = cli.Parse(cli.ArgsToVector(os.Args()))
```

`os.Args()` is `@[]readonly @[]readonly char` — element slots and text both
readonly — while `flags` binds mutable `@[]char` destinations. Dropping
element-level `readonly` is not implicit and is not a `cast`, so the vector has
to be copied element by element. **Every tool that parses its own command line
writes this loop, `bni` included** — its `bniArgs()` is the same code with the
same comment.

## Parsing a slice, not a process

A FlagSet parses an argument vector, which is why the parsing lives in `pkg/cli`
and not in `cmd/greet`: the whole grammar is covered by unit tests over literal
vectors, with no program to start.

```binate
if Parse(@[]@[]char{"--verbose=false"}).Verbose { … }
```

The command is then a thin bridge — real argv in, report out — and the
end-to-end harness runs it over five different argument vectors, since one run
proves almost nothing about a parser.

## Layout

```
pkg/cli.bni + cli/     Options, Parse, Usage, ArgsToVector
pkg/cli/cli_test.bn    10 tests over literal argument vectors
cmd/greet/             the tool: bridge argv, report, exit 2 on a parse error
tests/                 five vectors × both modes × fixtures
```

## Building and running

```sh
flags/tests/run.sh                              # five vectors, both modes
scripts/run-compiled.sh          flags/cmd/greet -v --name=Ada extra
scripts/run-interpreted.sh       flags/cmd/greet -h
scripts/run-tests-compiled.sh    flags/pkg/cli
scripts/run-tests-interpreted.sh flags/pkg/cli
```
