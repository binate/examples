10 REM Direct self-reference: FNF's body references FNF. ECMA-55
20 REM forbids a function referencing itself (no recursion), so this
30 REM is a load-time error and nothing is printed.
40 DEF FNF(X) = FNF(X) + 1
50 PRINT FNF(2)
60 END
