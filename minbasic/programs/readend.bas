10 REM READing more data than the sequence holds is a fatal ECMA-55 "out of
20 REM data" exception. There are two data here, so the third READ stops the
30 REM run with a diagnostic and line 80 is never reached.
40 READ A
50 READ B
60 PRINT A; B
70 READ C
80 PRINT "NOT REACHED"; C
90 DATA 10, 20
100 END
