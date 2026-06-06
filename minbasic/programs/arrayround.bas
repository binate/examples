10 REM Subscript expressions are ROUNDED to the nearest integer to index
20 REM (ECMA-55 clause 18). Store distinct values at indices 2 and 3, then read
30 REM with fractional subscripts: A(1.6) rounds to 2, A(2.5) rounds to 3.
40 DIM A(5)
50 LET A(2) = 222
60 LET A(3) = 333
70 PRINT "A(1.6)"; A(1.6)
80 PRINT "A(2.5)"; A(2.5)
90 END
