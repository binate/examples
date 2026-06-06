10 REM RETURN with no matching GOSUB is a fatal ECMA-55 exception: the run
20 REM stops with a clear diagnostic and line 50 is never reached.
30 PRINT "BEFORE"
40 RETURN
50 PRINT "AFTER"
60 END
