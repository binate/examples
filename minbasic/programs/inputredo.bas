10 REM INPUT that rejects a bad first reply and re-requests. The target is a
20 REM numeric variable, so a non-numeric datum (or the wrong number of data)
30 REM is a nonfatal exception: the reply is discarded, ?REDO FROM START is
40 REM shown, and the prompt repeats until a valid number is supplied.
50 PRINT "ENTER A WHOLE NUMBER";
60 INPUT K
70 PRINT "GOT"; K
80 END
