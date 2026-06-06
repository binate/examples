10 REM One-parameter user function used in a loop. The parameter X is
20 REM local to FNS and shadows the global X only during each call.
30 DEF FNS(X) = X * X
40 FOR I = 1 TO 5
50 PRINT I; FNS(I)
60 NEXT I
70 PRINT "FNS(1.5)"; FNS(1.5)
80 END
