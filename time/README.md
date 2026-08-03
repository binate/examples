# time — points, deltas, and the calendar that isn't there

`pkg/std/time` is deliberately small. A **Point** is a position on an idealized
timeline with no leap seconds; a **Delta** is a signed difference between two of
them. That is all: no years, no months, no time zones — and **no clock**.

## There is no `Now()`

Nothing in the standard library reads the current time. There is no `time.Now()`,
no `Sleep`, and no syscall underneath (`pkg/std/os/sys` has no
`clock_gettime`) to build one from. A Binate program cannot ask what time it is.

So every Point in `cmd/dates` comes from a constant or from arithmetic — with one
exception, which is the whole trick: the program writes a file and reads back its
**modification time**. That is the only channel through which today's date
reaches a Binate program, and the example uses it deliberately rather than
pretending the gap is not there. (It is a real limitation of the current library,
and it is tracked upstream.)

## A Point has no clock identity

Two Points can be compared or subtracted — but the operations treat both as plain
numbers, and cannot verify they came from the same source. A file's mtime from
one filesystem and a constant you wrote are both Points; nothing stops you
subtracting them, and nothing says the answer means anything. That judgment is
the caller's, exactly as a raw pointer's validity is.

`FromUnix` is the only sanctioned constructor. `Point`'s fields are public
because a by-value type must publish its layout, not because building one by hand
is supported — a Point with an out-of-range nanosecond has undefined ordering.

## What `pkg/cal` adds

The calendar is the missing piece, so this example supplies it (UTC, proleptic
Gregorian):

```
epoch                  1970-01-01 00:00:00 UTC
one second before      1969-12-31 23:59:59 UTC
day before             2100-02-28 00:00:00 UTC
day after              2100-03-01 00:00:00 UTC
```

`Civil` decomposes a Point into a `Date`; `At` puts one back together; `Format`
renders it. The algorithm is Howard Hinnant's — shift the year to start in March
so the leap day falls at the *end*, which turns the month lengths into an
arithmetic sequence and removes the need for a table.

**Floor division is the thing to get right.** Binate's `/` truncates toward zero,
like C's. A pre-epoch timestamp has a negative second count, so truncation would
place it one day late — `-1` would land on 1970-01-01 rather than 1969-12-31. So
`cal` uses explicit `floorDiv`/`floorMod` helpers throughout, and the tests pin
the three timestamps either side of the boundary.

**Normalization gives you date arithmetic for free.** `At` accepts out-of-range
fields and carries them, so month 13 is January of the next year and day 0 is the
last day of the previous month:

```
2000-13-01             2001-01-01 00:00:00 UTC
2000-03-00             2000-02-29 00:00:00 UTC
2000-01-366            2000-12-31 00:00:00 UTC
```

## Deltas

`Sub` gives a Delta, which is just a nanosecond count once computed —
`FormatDelta` renders it compactly, dropping leading units that are zero and
keeping trailing ones:

```
2000 - 1000            16m40s
1000 - 2000            -16m40s
with a fraction        1h13m30.5s (4410500000000 ns)
a century              876600h0m0s
```

A Delta holds nanoseconds in an `int64`, so its range is about **±292 years**. A
span wider than that overflows — which is why the "century" line above is near
the practical limit for a program that measures ages rather than epochs.

## Layout

```
pkg/cal.bni + cal/     Date, Civil, At, Format, FormatDelta, IsLeap, DaysInMonth
pkg/cal/cal_test.bn    9 tests, including a 400-point round-trip across negatives
cmd/dates/             the tour, plus the one real timestamp
tests/                 compiled == interpreted == fixture
```

The round-trip test is the one that matters: `At(Civil(p)) == p` over 400
timestamps spanning roughly ±2000 years, at a stride that is not a whole number
of days, so hours and minutes vary too. Spot checks confirm the dates a human
recognizes; the property catches the off-by-one they would miss.

## Building and running

```sh
time/tests/run.sh                               # compiled == interpreted == fixture
scripts/run-compiled.sh          time/cmd/dates /tmp/my-scratch
scripts/run-interpreted.sh       time/cmd/dates /tmp/my-scratch
scripts/run-tests-compiled.sh    time/pkg/cal
scripts/run-tests-interpreted.sh time/pkg/cal
```

The program takes a scratch directory (defaulting to `/tmp/binate-time-dates`),
writes one file in it to read a modification time, and removes what it made.
