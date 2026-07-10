# cinterop — calling external C library code

Two small programs that call **your own** external C code from Binate, using the
two C-interop intrinsics:

- **`__c_call("sym", RetType, args…)`** — call the C symbol `sym` (named
  verbatim, no Binate name mangling) with the C ABI. The C signature is spelled
  in Binate types at the call site; a `"void"` return spelling makes a
  result-less call.
- **`__c_global("sym", T)`** — the **address** of the C global variable `sym`,
  as a raw `*T` (never `@T` — the storage is the C side's, with no Binate
  refcount header). Read it with `*p`, write it with `*p = …`.

Both name their C symbol verbatim and are **compiled-mode only**: the bytecode VM
does no FFI, so this example has no interpreted path and no unit tests (a
`__c_call` can't run under the VM).

## The demo C library

[`csrc/rng.c`](csrc/rng.c) is a tiny deterministic PRNG (xorshift32) — a stand-in
for any external C library. It is deliberately *not* libc: the point is reaching
code that is yours, not the standard library. It exposes both things the
intrinsics reach:

| C symbol                         | reached from Binate by                          |
|----------------------------------|-------------------------------------------------|
| `void rng_seed(uint32_t)`        | `__c_call("rng_seed", "void", seed)`            |
| `uint32_t rng_next(void)`        | `__c_call("rng_next", uint32)`                  |
| `uint32_t rng_below(uint32_t)`   | `__c_call("rng_below", uint32, bound)`          |
| `uint32_t rng_state`             | `__c_global("rng_state", uint32)`               |

C `unsigned int` is 32-bit on all our targets, so it maps to `uint32` (not
Binate `int`, which is target-word-width). There is no header and nothing shared
with the Binate source: each call site names the symbol and spells its signature.

## The programs

- **[`cmd/callrng`](cmd/callrng/main.bn)** — drives the library entirely through
  `__c_call`, exercising all three call shapes: a void-return call (`rng_seed`),
  a no-argument call (`rng_next`), and a call with a value argument (`rng_below`).
- **[`cmd/globalrng`](cmd/globalrng/main.bn)** — reaches the library's global
  `rng_state` directly with `__c_global`: reads the default seed, then **writes
  through** the pointer to reseed and confirms the writes landed in the C
  library's own state (same seed reproduces a draw; a different seed changes it).

Expected output (pinned in [`tests/expected/`](tests/expected/)):

```
$ callrng
next & 1023: 202 465 852 146
below 100: 10 13 4 18 6 43

$ globalrng
default seed nonzero: yes
same seed reproduces draw: yes
different seed changes draw: yes
```

## Building and running

Linking a C object into a Binate program uses bnc's `--link-after-objs`: compile
the C source to an object with any C compiler, then hand the object to bnc, which
passes it to the final `clang` link. The end-to-end harness does exactly this:

```sh
cinterop/tests/run.sh
```

It compiles `csrc/*.c`, links each cmd, runs it, and diffs against the fixtures.

### Toolchain requirement

`__c_global` landed **after** `bnc-0.0.10` (the version pinned in the repo's
`BUILDER_VERSION`), so with the pinned toolchain the harness **skips** itself and
`build-all.sh` skips this example (it ships `csrc/`, so it is built by its own
harness, not the generic sweep). To run it now, build a bundle from a binate
`main` checkout and point at it:

```sh
# in a binate checkout, once, to produce a bundle with __c_global:
binate/scripts/make-bundle.sh --out-dir /tmp/dist          # writes a .tar.gz
mkdir -p /tmp/binate-main && tar -xzf /tmp/dist/*.tar.gz -C /tmp/binate-main --strip-components=1

BINATE_BUNDLE=/tmp/binate-main cinterop/tests/run.sh        # -> PASS
```

`BINATE_BUNDLE` points the example scripts at a pre-built bundle directly (no
download, no version pin). Once `BUILDER_VERSION` names a release that includes
`__c_global`, the harness activates on the pinned toolchain automatically — no
edit here needed.
