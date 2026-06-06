10 REM 2-D array: build a 3x3 identity matrix, then print it row by row
20 OPTION BASE 1
30 DIM M(3,3)
40 FOR I = 1 TO 3
50 FOR J = 1 TO 3
60 LET M(I,J) = 0
70 IF I <> J THEN 90
80 LET M(I,J) = 1
90 NEXT J
100 NEXT I
110 FOR I = 1 TO 3
120 PRINT M(I,1); M(I,2); M(I,3)
130 NEXT I
140 END
