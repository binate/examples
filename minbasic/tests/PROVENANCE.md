# Provenance of the vendored NBS test programs

The `*.BAS` programs under `tests/nbs/` are from the **NBS Minimal BASIC test
programs, Version 2**, published by the U.S. National Bureau of Standards (NBS,
now NIST) as **NBS Special Publication 500-70, Volumes 1 & 2** (November 1980):

- <https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nbsspecialpublication500-70v1.pdf>
- <https://nvlpubs.nist.gov/nistpubs/Legacy/SP/nbsspecialpublication500-70v2.pdf>

They are the canonical conformance suite for ECMA-55 / ANSI X3.60-1978 Minimal
BASIC (the "PROGRAM FILE n" programs, P001..P208).

## Public-domain status

The NBS test programs are a work of the U.S. federal government and are therefore
**not subject to domestic copyright** (17 USC §105) — effectively public domain.
We vendor only the `.BAS` program files on that basis.

## Transcription

The machine-readable text of these programs was transcribed from the 1980 NBS
PDFs by **John Gatewood Ham** (author of the ECMA-55 Minimal BASIC Compiler,
<http://buraphakit.sourceforge.net/BASIC.shtml>). We took our copies from the
**bas55** project by Jorge Giner Cordero (<https://github.com/jorgicor/bas55>),
whose `tests/README.md` confirms the `.BAS` programs originate from NBS SP 500-70
and explicitly carves them out of bas55's own licensing.

## What is NOT included

bas55's own test fixtures and harness — the `*.ok` / `*.eok` expected-output
files, the `*.test` driver scripts, and `chkout.inc` — are licensed **GPL-3.0**
and are **deliberately NOT vendored here**. Those files encode bas55's specific
output (its RND sequence, its float formatting, its diagnostic text), so they are
not a neutral oracle for a different implementation anyway.

Our expected-output fixtures under `tests/expected/` are **our own** — produced
by running minbasic itself (see `tests/README.md`). They were spot-validated
against bas55's `.ok` during development as a cross-implementation sanity check,
but the committed fixtures are minbasic's output, not bas55's.
