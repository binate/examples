10 REM An ON...GOTO selector outside 1..(number of listed lines) is a fatal
20 REM ECMA-55 exception. Here K = 4 with only three targets, so the run
30 REM stops with a diagnostic and line 60 is never reached.
40 LET K = 4
50 ON K GOTO 100, 110, 120
60 PRINT "NOT REACHED"
100 PRINT "ONE"
105 STOP
110 PRINT "TWO"
115 STOP
120 PRINT "THREE"
130 END
