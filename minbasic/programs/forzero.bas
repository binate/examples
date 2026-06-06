10 REM Zero-trip FOR: init already past the limit, so the body never runs.
20 REM "IN" should not print; the control variable keeps its initial value.
30 LET C = 0
40 FOR I = 5 TO 1
50 PRINT "IN"; I
60 LET C = C + 1
70 NEXT I
80 PRINT "BODY RAN"; C
90 PRINT "I IS"; I
100 END
