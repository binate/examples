# processes — running a child program

`pkg/std/os/process` launches a program, waits for it, and reports how it ended.
That is the whole API surface: synchronous, no pipes, no job control.

## A non-zero exit is not an error

This is the distinction the API is built around, and it is different from what
most people expect:

```binate
st, err := process.RunArgs("/bin/false")
present(err)     // false — it ran fine
st.Success()     // false — it ran fine and exited 1
```

The trailing `@errors.Error` is present **only** when the child could not be
*started* — the path did not resolve, or fork/exec failed. Once a child starts,
everything it does comes back in the `ExitStatus`: exit 0, exit 7, or death by
signal. So `present(err)` answers "did it run at all" and the `ExitStatus`
answers "how did it go", and the two never get conflated.

## The status cannot be misread

Exactly one of `Exited()` and `Signaled()` holds, and a signal death reports
`Code() == -1` — never a valid 0..255 code — precisely so a naive `Code() == 0`
check cannot mistake a killed child for a clean one:

```
exit 0:  Exited true,  Code 0,  Signal 0,   Success true
exit 7:  Exited true,  Code 7,  Signal 0,   Success false
SIGTERM: Exited false, Code -1, Signal 15,  Success false
```

`Signal()` is the raw host signal number, which is not portable in general;
SIGTERM is 15 everywhere POSIX, which is why the example uses it.

## Options: the zero value is the safe default

`Options{}` means *inherit the environment, use `program` as an exact path, argv[0]
= `program`, no arguments*. Each field opts into something else:

| field | effect |
|---|---|
| `Args` | argv[1..] — it does **not** include argv[0], which would be a shift-by-one footgun |
| `Argv0` | what the child sees as its own name (how a multi-call binary dispatches) |
| `Env` | replaces the environment rather than adding to it |
| `ReplaceEnv` | makes an *empty* `Env` mean "an empty environment" instead of "inherit" |
| `SearchPath` | resolve `program` along `PATH` instead of treating it as an exact path |

The `Env`/`ReplaceEnv` pair is worth reading twice: `Options{}` inherits,
`Options{Env: e}` replaces with `e`, and `Options{ReplaceEnv: true}` hands the
child an empty environment. `pkg/proc`'s `ShEnv` sets `ReplaceEnv` so that
passing an empty list means what it says.

## The child shares your stdout

There is no capture in this API — the child inherits standard input, output, and
error. In the demo's output, `hello from the child` is written by `/bin/echo`,
not by the example. The ordering is still deterministic: `process.Run` waits for
the child, so its output necessarily precedes the parent's report of it.

That is also why everything here communicates through **exit codes**: with no
pipe available, `exit ${MARK:-9}` is how the demo and the unit tests find out
what the child saw in its environment.

## Layout

```
pkg/proc.bni + proc/       Describe, EnvValue, Sh, ShEnv
pkg/proc/proc_test.bn      8 tests — real children, plus pure environment parsing
cmd/spawn/                 the tour: exit codes, a signal, env, argv0, LookPath
tests/                     compiled == interpreted == fixture
```

One signature is worth explaining: `Sh(script @[]readonly char)` takes an
*owning* handle where a read-only parameter would normally be a borrow, because
`ShEnv` has to place it into an `@[]readonly @[]readonly char` — a slice of
owning handles — to build `Options.Args`, and a raw borrow never converts to an
owning handle. A string literal is already `@[]readonly char`, so it costs
callers nothing.

## Building and running

```sh
processes/tests/run.sh                          # compiled == interpreted == fixture
scripts/run-compiled.sh          processes/cmd/spawn
scripts/run-interpreted.sh       processes/cmd/spawn
scripts/run-tests-compiled.sh    processes/pkg/proc
scripts/run-tests-interpreted.sh processes/pkg/proc
```

Needs a POSIX shell and `/bin/echo`. The bytecode VM reaches the same fork/exec
layer the compiler does, so both modes behave identically — this is ordinary
library code, not FFI.
