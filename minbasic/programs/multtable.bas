10 REM 2-D multiplication table M(i,j)=i*j for 1..4, under OPTION BASE 1 so the
20 REM valid subscripts are 1..4 (index 0 is now out of range and unused).
30 OPTION BASE 1
40 DIM M(4,4)
50 FOR I = 1 TO 4
60 FOR J = 1 TO 4
70 LET M(I,J) = I * J
80 NEXT J
90 NEXT I
100 FOR I = 1 TO 4
110 PRINT M(I,1); M(I,2); M(I,3); M(I,4)
120 NEXT I
130 END
