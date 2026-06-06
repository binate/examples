10 REM INPUT a quoted string whose interior spaces are significant. A quoted
20 REM datum keeps everything between the quotes verbatim, so the leading and
30 REM trailing spaces inside the quotes are preserved in the stored string.
40 PRINT "ENTER A QUOTED PHRASE";
50 INPUT P$
60 PRINT "["; P$; "]"
70 END
