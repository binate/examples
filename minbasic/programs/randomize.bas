10 REM RANDOMIZE is parsed (its keyword is reserved) but its effect is deferred:
20 REM reseeding to an unpredictable point needs an entropy source the bundle
30 REM does not provide, so executing it is a clean fatal and line 50 is skipped.
40 PRINT "BEFORE"
45 RANDOMIZE
50 PRINT "AFTER"
60 END
