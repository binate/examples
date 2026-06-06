10 REM GOTO loop with an IF...THEN exit test (count 1..5 then stop)
20 LET N = 1
30 PRINT N;
40 LET N = N + 1
50 IF N <= 5 THEN 30
60 PRINT
70 IF N <> 6 THEN 90
80 PRINT "N REACHED 6"
90 END
