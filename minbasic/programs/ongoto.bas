10 REM ON...GOTO selects the K-th listed line (1-based, rounded). Drive it
20 REM with K = 1, 2, 3 and confirm each lands on its own branch.
30 LET K = 1
40 ON K GO TO 100, 200, 300
100 PRINT "ONE"
110 GOTO 400
200 PRINT "TWO"
210 GOTO 400
300 PRINT "THREE"
310 GOTO 400
400 LET K = K + 1
410 IF K <= 3 THEN 40
420 REM Selector rounding: 2.6 rounds to 3 -> branch THREE, then stop.
430 ON 2.6 GOTO 500, 510, 520
500 PRINT "ROUND ONE"
505 STOP
510 PRINT "ROUND TWO"
515 STOP
520 PRINT "ROUND THREE"
530 END
