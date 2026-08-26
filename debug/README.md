# debug — reading your own call stack

`pkg/std/debug` captures the running program's call stack. It works in both
execution modes — compiled code walks the hardware frame-pointer chain, the
bytecode VM walks its own — and what comes back is **raw**:

```binate
type Frame struct {
	Mode int   // FRAME_NATIVE or FRAME_VM
	Loc  int   // a return address, or a VM function index
}
```

Nothing is symbolized. Turning a `Loc` into a function name and a source line is
a later phase of the library, so an example written today has to be honest about
what a frame can actually tell you.

## Almost nothing here is printable

A `Loc` is an address or an index — different every run, and meaning different
things in the two modes. Even the *depth* is not portable: the entry machinery
below `main` is deeper when compiled than under the VM, and its size depends on
the platform's startup chain. So `cmd/frames` prints no absolute number at all.

What survives is the arithmetic, and it holds identically in both modes:

```
each call adds one frame:
  1 call(s) deeper: +1
  ...
skipping 1 removes 1, skipping past the top leaves 0
a 1-frame buffer holds 1 and reports more (truncated true)
a 64-frame buffer holds every frame (truncated false)
```

## The buffer contract

`Callers(skip, into)` fills `into` and returns **how many frames there were**,
not how many it wrote. A return greater than `len(into)` means the capture was
truncated — which is what lets a caller size a buffer in two passes instead of
guessing. `pkg/trace`'s `Capture` returns both numbers so the difference is
visible.

`skip` removes frames from the top of the report and **floors at zero** rather
than going negative. That floor is easy to miss, because a deep stack hides it:
an earlier version of `TestSkipRemovesFrames` asserted `Callers(k) == full - k`
and passed compiled while failing interpreted, since the VM's test stack is
shallower and reached the floor first. The test now asserts the documented
contract — `max(full - k, 0)` — across the whole range.

## The one thing a frame says outright

`Frame.Mode` tags the frame as native or VM, so a program can ask **which mode it
is running in**:

```binate
f, ok := debug.Caller(0)
// f.Mode == debug.FRAME_VM  →  interpreted
```

This is worth pausing on, because it is the *only* place a Binate program can
observe the difference. Everything else about the two modes is defined to be
identical — same layouts, same heap, same results — and the rest of this repo
exists partly to demonstrate that. A stack frame is where the abstraction is
deliberately transparent, because a frame *is* the execution machinery.

That makes this the only example whose fixtures differ by mode. They differ in
exactly one line, and the harness checks that:

```
running compiled        # tests/expected/compiled.txt
running interpreted     # tests/expected/interpreted.txt
```

`trace.Uniform()` confirms the assumption behind reading a single frame: one
capture never mixes native and VM frames.

## Layout

```
pkg/trace.bni + trace/     Mode, Depth, DepthAt, Capture, Uniform
pkg/trace/trace_test.bn    8 tests, all of them relative or contractual
cmd/frames/                the tour
tests/                     one fixture per mode, differing in one line
```

One incidental language note, from `pkg/trace`: the two mode names could not be
`const`. In Binate, `const` is compile-time **scalars only** — text is a slice,
so an immutable non-scalar is `var x readonly T`, and here plain literals were
simpler.

## Building and running

```sh
debug/tests/run.sh                              # both modes, one fixture each
scripts/run-compiled.sh          debug/cmd/frames
scripts/run-interpreted.sh       debug/cmd/frames
scripts/run-tests-compiled.sh    debug/pkg/trace
scripts/run-tests-interpreted.sh debug/pkg/trace
```
