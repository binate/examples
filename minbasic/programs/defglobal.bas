10 REM The body of FNA reads its parameter X and the GLOBAL variable C.
20 REM The parameter X is local: calling FNA(7) must NOT clobber the
30 REM program-global X, which keeps its value 100 across the call.
40 DEF FNA(X) = X + C
50 LET C = 5
60 LET X = 100
70 PRINT "FNA(7)"; FNA(7)
80 PRINT "X AFTER"; X
90 LET C = 20
100 PRINT "FNA(X)"; FNA(X)
110 PRINT "X STILL"; X
120 END
