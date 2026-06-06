10 REM Default (implicit) dimensioning: B is never DIMed, so its first reference
20 REM B(I) fixes it as 1-D with upper bound 10 (valid subscripts 0..10). Fill
30 REM 0..10 with I+1 and read back the last element B(10) (expect 11).
40 FOR I = 0 TO 10
50 LET B(I) = I + 1
60 NEXT I
70 PRINT "B(0)"; B(0)
80 PRINT "B(10)"; B(10)
90 END
