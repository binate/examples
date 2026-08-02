# files — files and byte streams

A tour of `pkg/std/os` — create, write, read, seek, stat, list, rename, remove —
over the byte-stream interfaces in `pkg/std/io`, plus the two whole-stream
helpers those interfaces make possible.

## Errors are values, and they are classified

Every call that can fail returns a trailing `@errors.Error`. There is no `nil`
for an interface value, so the test is `present(err)`:

```binate
f, err := os.Open(path)
if present(err) { … }
```

Failures are not just messages — they root in the standard hierarchy, so a caller
matches on the *kind* rather than parsing text:

```binate
errors.Is(err, errors.NotFound)         // true for a missing path
errors.Is(err, errors.ConditionsUnmet)  // also true — NotFound roots in it
```

The tour prints both, for a missing file and for a double `Remove`.

## End of input is an error value

A `Read` reports exhaustion by returning `io.EOF`, not by returning zero. The
loop shape follows from two rules:

```binate
for {
    n, err := f.Read(buf)
    total = total + n          // honor n FIRST: a Read may deliver bytes AND fail
    if present(err) {
        if !io.IsEOF(err) { … real failure … }
        break
    }
}
```

`io.IsEOF` goes through `errors.Is`, so it still matches when a reader has
wrapped the EOF with context. `pkg/fio`'s `ReadAll` and `Copy` encode both rules
once, and `fio_test.bn` pins them with a reader that delivers a byte and fails in
the same call.

## Buffers are borrows; a File is a handle you close

`Read(p *[]uint8)` and `Write(p *[]readonly uint8)` take **raw slices** — 2-word
borrows into memory the caller owns, which the callee does not retain. That is
why the tour allocates one `@[]uint8` and reuses it for every read.

A `File`, by contrast, is an owning `@File`, and **Binate runs no finalizers** —
ever. A `File` dropped without `Close` leaks its descriptor until the process
exits, so every open in the tour has a matching close. There is no `defer`;
deterministic release is the language's answer, but a *descriptor* is the
kernel's resource, not the refcount's.

## Code against the interface, not the file

`pkg/fio` takes `@io.Reader` / `@io.Writer` rather than `@os.File`:

```binate
func ReadAll(r @io.Reader) (@[]readonly char, @errors.Error)
func Copy(dst @io.Writer, src @io.Reader) (int, @errors.Error)
```

Which is why the tour can copy one file to another with the same `Copy` the tests
drive with a fake in-memory stream — and why those tests need no filesystem at
all. `fio_test.bn` implements `io.Reader` three ways (a chunked reader, an
empty one, and one that fails mid-stream) and `io.Writer` once (a writer that
refuses to take everything), each a struct plus a matching method plus the `impl`
line, since a matching method set alone never satisfies an interface.

A `strings.Builder` is an `io.Writer` too, so `Copy(builder, reader)` reads a
stream into memory with no file involved.

## Position, and the two ways to read

`Read` and `Write` advance a position that lives **in the kernel**, not in the
`File`. `Seek` moves it. `ReadAt`/`WriteAt` carry their own offset and do not
touch it — the tour seeks to 7, reads 5 bytes, then `ReadAt`s from 0 and shows
the position is still exactly where the `Read` left it.

## What Stat tells you, and what it does not

`os.Stat` returns a **snapshot**: `Size`, `Mode` (a portable `FileMode`, laid out
like Go's), and `ModTime` as a `time.Point`. `ReadDir` additionally reports each
entry's *type* bits, so "is this a subdirectory?" costs no second call.

Two things the tour deliberately does not print, because they are not portable:
**permission bits** (they depend on the process umask) and **times** (a
`time.Point` from the filesystem is different on every run — and `pkg/std/time`
has no clock at all, so a Point can only be compared, subtracted, or converted
with `ToUnix`, never obtained from "now"). `os.ReadDir` also returns entries in
the directory's own order, which is not an order — the tour sorts before
printing.

## Layout

```
pkg/fio.bni + fio/     ReadAll and Copy over io.Reader / io.Writer
pkg/fio/fio_test.bn    fake streams — 5 tests, no filesystem needed
cmd/tour/              the os walkthrough, in a scratch directory
tests/                 compiled == interpreted == fixture
```

The tour takes its scratch directory as an argument (defaulting to
`/tmp/binate-files-tour`), creates what it needs, and removes it on the way out;
the harness gives each mode its own and fails if either is left behind.

## Building and running

```sh
files/tests/run.sh                          # compiled == interpreted == fixture
scripts/run-compiled.sh          files/cmd/tour /tmp/my-scratch
scripts/run-interpreted.sh       files/cmd/tour /tmp/my-scratch
scripts/run-tests-compiled.sh    files/pkg/fio
scripts/run-tests-interpreted.sh files/pkg/fio
```

Expected output is pinned in [`tests/expected.txt`](tests/expected.txt). The
bytecode VM reaches the same libc-backed file layer the compiler does, so both
modes produce identical output — this is ordinary library code, not FFI.
