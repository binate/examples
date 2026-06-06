10 REM 1-D array: fill A(1..5) with squares, then sum them (expect 55)
20 DIM A(5)
30 FOR I = 1 TO 5
40 LET A(I) = I * I
50 NEXT I
60 LET S = 0
70 FOR I = 1 TO 5
80 LET S = S + A(I)
90 NEXT I
100 PRINT "SQUARES"; A(1); A(2); A(3); A(4); A(5)
110 PRINT "SUM"; S
120 END
