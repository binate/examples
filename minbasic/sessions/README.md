# minbasic REPL session fixtures

Each `*.in` file is a REPL session script: one host-read line per text line, fed
to `cmd/basic` on standard input. Each `*.out` is the committed expected
transcript — the exact bytes `cmd/basic` writes to standard output for that
session, including the banner, the `> ` prompts, LIST output, immediate-mode
results, diagnostics, and the BASIC program's PRINT output (all on one stream by
design, so a piped session is deterministic). EOF (end of the `.in` file) ends
the session cleanly; the final `> ` prompt with no following line is the prompt
shown just before the EOF read.

`./run.sh` (run from the examples repo root, `BINATE_BUNDLE` set) drives every
script through `cmd/basic` **compiled and interpreted** and asserts
compiled == interpreted == the committed `.out`.

Cases covered:

- **edit-list-run** — numbered lines entered out of order, `LIST` shows them
  sorted; replacing a line (re-entering its number); deleting a line (a bare line
  number) then `LIST`; `RUN` of the stored program; `NEW` then `LIST` (empty).
- **immediate-vars** — immediate `PRINT 2+2` and `LET A=5` then inspecting `A`;
  a stored program; `RUN`; then immediate `PRINT` of the variables the program
  left behind (RUN resets variables before running, retains their final values
  afterward).
- **parse-error** — a parse error on a numbered line is reported and the line is
  NOT stored (the following `LIST` omits it); the session continues, accepts more
  lines, and `RUN`s.
- **input-run** — a stored program with an `INPUT` statement is `RUN`; the reply
  line is read from the SAME stdin stream the REPL command loop reads (one shared
  host reader), so the line after `RUN` is consumed by the program's `INPUT`
  rather than treated as a command; a following immediate `PRINT` shows the
  variable the program's `INPUT` set.
