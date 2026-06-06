10 REM Supplied numeric functions ABS / SGN / INT on positive,
20 REM negative, and zero arguments. INT is floor toward -infinity.
30 PRINT "ABS"; ABS(5); ABS(-5); ABS(0)
40 PRINT "SGN"; SGN(3); SGN(-3); SGN(0)
50 PRINT "INT"; INT(1.7); INT(-1.3); INT(0)
60 PRINT "INTNEG"; INT(-2); INT(-0.5)
70 LET X = -4.5
80 PRINT "EXPR"; ABS(X) + INT(X) * SGN(X)
90 END
