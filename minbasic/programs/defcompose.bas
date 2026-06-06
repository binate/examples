10 REM One user function calling another: FNC squares (via FNB) then
20 REM adds one. FNB must be defined on a lower-numbered line than the
30 REM FNC body that references it.
40 DEF FNB(X) = X * X
50 DEF FNC(Y) = FNB(Y) + 1
60 PRINT "FNB(4)"; FNB(4)
70 PRINT "FNC(4)"; FNC(4)
80 PRINT "FNC(FNB(2))"; FNC(FNB(2))
90 END
