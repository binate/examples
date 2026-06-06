10 REM FOR/NEXT sum of 1..10 (expect 55), then the control variable's
20 REM final value after a normal exit (expect 11 = stepped past the limit)
30 LET S = 0
40 FOR I = 1 TO 10
50 LET S = S + I
60 NEXT I
70 PRINT "SUM"; S
80 PRINT "FINAL I"; I
90 END
