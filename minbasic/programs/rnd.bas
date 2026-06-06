10 REM RND draws from a reproducible pseudo-random sequence. Without RANDOMIZE
20 REM the same sequence is produced on every run (ECMA-55 clause 9). Print five
30 REM values scaled to 0..999; INT keeps them whole and in range.
40 FOR I = 1 TO 5
50 PRINT INT(RND * 1000)
60 NEXT I
70 END
