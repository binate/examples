10 REM TAB positioning: forward to a column, and a TAB into an
20 REM already-passed column forcing a new line.
30 PRINT TAB(10); "X"
40 PRINT "ABC"; TAB(8); "Y"
50 PRINT "1234567890123456"; TAB(5); "WRAP"
60 PRINT TAB(3); "A"; TAB(3); "B"
70 REM TAB past the margin (75) reduces modulo it: TAB(78) -> column 3.
80 PRINT TAB(78); "M"
90 END
