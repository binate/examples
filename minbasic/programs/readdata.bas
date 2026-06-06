10 REM READ pulls successive data from the one global sequence (all DATA
20 REM lines, in order). Loop reading number/label pairs until the 0
30 REM sentinel, then RESTORE and re-read the first pair to show the
40 REM pointer reset. The data mixes numeric constants with quoted and
50 REM unquoted strings; spaces around an unquoted datum are trimmed, but a
60 REM quoted string keeps its interior spaces verbatim.
70 READ N
80 IF N = 0 THEN 200
90 READ L$
100 PRINT N; L$
110 GOTO 70
200 REM Hit the 0 sentinel; reset and re-read just the first pair.
210 RESTORE
220 READ N
230 READ L$
240 PRINT "AGAIN"; N; L$
250 STOP
300 DATA 1, ONE
310 DATA 2, "two words"
320 DATA 3, " PADDED "
330 DATA 0, DONE
340 END
