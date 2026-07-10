/*
 * rng.c — a tiny demo C "library" for the Binate C-interop examples to link
 * against.  It is deliberately NOT part of the C standard library: the point
 * of these examples is calling *your own* external C code from Binate, which a
 * libc symbol wouldn't illustrate.
 *
 * The library is a deterministic 32-bit PRNG (xorshift32).  It exposes both of
 * the things the two intrinsics reach:
 *   - three functions, called from Binate with __c_call (see cmd/callrng);
 *   - one global variable, addressed from Binate with __c_global (cmd/globalrng).
 *
 * There is no header: the Binate side names each symbol verbatim at the call
 * site and spells the C signature in Binate types, so nothing here needs to be
 * shared with the Binate source.  Build it to an object with any C compiler and
 * hand the object to bnc's `--link-after-objs`; cinterop/tests/run.sh does this.
 */

#include <stdint.h>

/*
 * rng_state is the generator's global state.  Binate reaches it as a C global:
 *   var p *uint32 = __c_global("rng_state", uint32)
 * yields its ADDRESS (a raw *uint32 — the storage is the C side's, no Binate
 * refcount header).  Read the state with *p; reseed the generator with *p = v.
 *
 * The initial value is xorshift32's canonical nonzero seed (the state must be
 * nonzero, or the sequence collapses to all-zero).
 */
uint32_t rng_state = 2463534242u;

/*
 * rng_seed resets the state.  A void C function — Binate calls it with the
 * "void" return spelling:  __c_call("rng_seed", "void", seed).  seed should be
 * nonzero.
 */
void rng_seed(uint32_t seed) {
    rng_state = seed;
}

/*
 * rng_next advances the state and returns the new 32-bit value.  It takes no
 * arguments:  __c_call("rng_next", uint32).
 */
uint32_t rng_next(void) {
    uint32_t x = rng_state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    rng_state = x;
    return x;
}

/*
 * rng_below returns a value in [0, bound), i.e. rng_next() % bound.  It takes
 * one argument, demonstrating a C call with a value argument:
 *   __c_call("rng_below", uint32, bound).
 * bound must be > 0.
 */
uint32_t rng_below(uint32_t bound) {
    return rng_next() % bound;
}
