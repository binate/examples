10 REM Default OPTION BASE 0: a DIM A(3) array has valid subscripts 0..3, so
20 REM index 0 is a real element. Fill 0..3 and sum (0+10+20+30 = 60).
30 DIM A(3)
40 FOR I = 0 TO 3
50 LET A(I) = I * 10
60 NEXT I
70 LET S = 0
80 FOR I = 0 TO 3
90 LET S = S + A(I)
100 NEXT I
110 PRINT "A(0)"; A(0)
120 PRINT "SUM 0..3"; S
130 END
