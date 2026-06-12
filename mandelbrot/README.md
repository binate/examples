# mandelbrot

Renders the **Mandelbrot set** as ASCII art. It is split into an abstract
escape-time **calculator** and a separate **ASCII renderer**, wired together by a
small command — the point of the example is that split.

```
mandelbrot/
  pkg/mandel.bni        Window, Compute, Escape
  pkg/mandel/mandel.bn  the escape-time calculator — pure compute, no I/O
  pkg/ascii.bni         Renderer, New, Sink, Picture
  pkg/ascii/ascii.bn    maps escape counts to a shading ramp
  cmd/mandelbrot/       runnable — renders a fixed view to standard output
```

Both packages are private to this example; they resolve as `import "pkg/mandel"`
and `import "pkg/ascii"` because `mandelbrot/` is the package search root.

## The calculator / renderer split

`pkg/mandel` knows nothing about characters. `Compute` walks a `cols×rows` grid
over a `Window` of the complex plane and, for each sample, hands its escape count
to a caller-supplied plot function:

```
func Compute(win Window, cols int, rows int, maxIters int, plot @func(int, int, int))
```

The escape count is the iteration at which `z := z² + c` first leaves the escape
radius (`|z| > 2`), or `-1` if the orbit stays bounded through `maxIters` (the
sample is taken to be inside the set).

`pkg/ascii`'s `Renderer` is one such plot target. `Sink()` returns a closure that
**captures the Renderer**, so each plotted sample lands in that Renderer's grid —
no shared globals, and the calculator stays oblivious to what consumes its
output:

```
var r @ascii.Renderer = ascii.New(COLS, ROWS, MAX_ITERS)
mandel.Compute(win, COLS, ROWS, MAX_ITERS, r.Sink())   // r.Sink() captures r
bootstrap.Write(bootstrap.STDOUT, r.Picture())
```

A different consumer — a pixel image, a histogram of escape counts — just
supplies a different plot closure; `pkg/mandel` is unchanged.

## Run it

```sh
./scripts/run-compiled.sh    mandelbrot/cmd/mandelbrot
./scripts/run-interpreted.sh mandelbrot/cmd/mandelbrot   # byte-identical output
```

```
                                                     . ..
                                                    +.:.
                                                  .*@@@@:.
                                                  .@@@@@-.
                                         .:.. .-.@@@@@@@#@@.:=    @
                                          =@@@@@@@@@@@@@@@@@@@+@@@:.
                                       :..@@@@@@@@@@@@@@@@@@@@@@@.
                        .     .        .:@@@@@@@@@@@@@@@@@@@@@@@@@...
                         .:....=..    :@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
                         ..@@@@@@@@@..+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
                    :   .%@@@@@@@@@@@:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
                  . .:@@-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                  . .:@@-@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
                    :   .%@@@@@@@@@@@:@@@@@@@@@@@@@@@@@@@@@@@@@@@@@-
                         ..@@@@@@@@@..+@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
                         .:....=..    :@@@@@@@@@@@@@@@@@@@@@@@@@@@@.
                        .     .        .:@@@@@@@@@@@@@@@@@@@@@@@@@...
                                       :..@@@@@@@@@@@@@@@@@@@@@@@.
                                          =@@@@@@@@@@@@@@@@@@@+@@@:.
                                         .:.. .-.@@@@@@@#@@.:=    @
                                                  .@@@@@-.
                                                  .*@@@@:.
                                                    +.:.
                                                     . ..
```

To change the view or resolution, edit the `COLS`/`ROWS`/`MAX_ITERS` constants
and the `Window` in `cmd/mandelbrot/main.bn`.

## Determinism

The pixel→coordinate mapping uses only `int→float` casts and IEEE double
arithmetic, so the picture is bit-identical compiled vs. interpreted and across
hosts. It deliberately avoids `float→int` casts of computed values, whose result
for out-of-range / non-finite inputs is still platform-dependent (see the repo
[`TODO.md`](../TODO.md)). `tests/run.sh` pins the picture against
`tests/expected.txt` in both modes.

## Tests

```sh
./scripts/run-tests-compiled.sh mandelbrot/pkg/mandel   # the calculator kernel + sweep
./scripts/run-tests-compiled.sh mandelbrot/pkg/ascii    # glyph mapping + the render path
mandelbrot/tests/run.sh                                 # end-to-end picture, both modes
```
