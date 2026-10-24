# Stage 1 QA — all 21 invalid inputs in concurrent Native program pairs

This additional QA-only Native PyFunge-98 job builds on the passing
same-Program 21-invalid reset test and the separately passing 12-input
AB/BA and three-quantum live-pair matrices.

**New finite corpus:** the exact six invalid numeric and fifteen invalid
lexical inputs already verified individually are each paired with one
valid input. Eleven further pairs exercise invalid-invalid combinations.
The 32 pairs run in two new quantum schedules, A7/B11 AB and B5/A13 BA.
That is 64 simultaneous-program pair trials / 128 actual Native Program
executions. Valid seven-field outputs are obtained from the independent
Native Befunge-98 work_counts + two save reference invocations for six
distinct valid inputs, never from Python calendar calculations.
Invalid outputs must be seven -1 sentinels.

The runtime independently checks that every actual Funge-space.get,
Funge-space.put and Funge-space.putspace access is to the active Program's
own space. All Native p writes must correspond to actual p instructions,
putspace must remain unused, peer IP/stack/space/I-O snapshots must not
change during the other Program's quantum, and instruction/read/write/
output signatures for each case must be peer/schedule invariant.

A separate Python-3 audit checks the complete input/peer/schedule matrix,
all 27 unique input signatures and 16 adversarial report mutations.
This does not prove all possible inputs, all undocumented memory APIs,
or full Stage-1 functional, geometric or semantic ownership acceptance.
The algorithm, canonical branch, main, and Stage 2 are unchanged.
