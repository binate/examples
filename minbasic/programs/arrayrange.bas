10 REM Subscript out of range is a FATAL exception (ECMA-55 clause 18.5). A(5)
20 REM is valid (it prints), but A(6) is past the DIM A(5) upper bound, so the
30 REM program terminates with a diagnostic and line 60 never prints.
40 DIM A(5)
50 PRINT "A(5)"; A(5)
60 PRINT "A(6)"; A(6)
70 PRINT "UNREACHED"
80 END
