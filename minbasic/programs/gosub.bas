10 REM GOSUB called from two sites + a nested GOSUB. Each RETURN must resume
20 REM at the line after its own GOSUB, so the BACK markers interleave the
30 REM subroutine output in caller order.
40 PRINT "CALL 1"
50 GOSUB 200
60 PRINT "BACK 1"
70 PRINT "CALL 2"
80 GO SUB 200
90 PRINT "BACK 2"
100 STOP
200 REM Subroutine: print a banner, then nest into a deeper subroutine.
210 PRINT "  SUB A"
220 GOSUB 300
230 PRINT "  SUB A DONE"
240 RETURN
300 PRINT "    SUB B"
310 RETURN
320 END
