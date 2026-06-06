10 REM Reference-before-DEF: FNR is used on line 30, before its DEF on
20 REM line 40. ECMA-55 requires the DEF on a lower-numbered line, so
30 PRINT FNR(3)
40 DEF FNR(X) = X + 1
50 END
