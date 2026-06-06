10 REM No-parameter user function: a named numeric constant. A bare
20 REM reference FNP (no parentheses) evaluates the body.
30 DEF FNP = 3.14159
40 LET R = 2
50 PRINT "PI"; FNP
60 PRINT "AREA"; FNP * R * R
70 END
