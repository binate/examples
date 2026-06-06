10 REM The simple variable A and the array A(...) share a letter but are
20 REM SEPARATE namespaces. Set A = 7 and A(0) = 99 independently and show
30 REM neither disturbs the other.
40 DIM A(2)
50 LET A = 7
60 LET A(0) = 99
70 LET A(1) = 100
80 PRINT "SCALAR A"; A
90 PRINT "ARRAY A(0)"; A(0)
100 PRINT "ARRAY A(1)"; A(1)
110 END
