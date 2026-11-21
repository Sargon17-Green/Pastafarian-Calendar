# Stage19 selected Native failure diagnostic — 2026-11-21
PROJECT_ID: PC-BRANCH-FALSE-ARABIC; branch FALSE+العربية.

- Run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44940370617 ; job 136956021261; completed/failure on source SHA 71ca0374f1820dc425e7c7a09259eed2cded07c0.
- Original interpreter eb3135565a8670cced3f6bbca4dbf7b014c45634 compiled and Unicode preflight passed; independent JS oracle and Python fixtures generated.
- Preserved artifact 14722931126 ZIP SHA256 e410ce588e7c8a3de5d4328b4012618f257f61a088ae97474115a72387acd30d; 40 entries, CRC passed.
- Positive first chunk, 12 probes, two bad lengths and two mutants all exited 1 with stack type mismatch at line 795, column 27 before any expected result marker. Thus neither positive nor negative controls passed.
- Root cause: op36 returns a small scalar. Its fixture expression `36h;!!o:` dereferenced twice, incorrectly treating the scalar as a heap pointer. Three generator call sites are scoped to `36h;!o:`: exhaustive tests, probes and invalid header controls. No change to production code or first-match oracle.
- Not yet verified: fixed Native execution, complete 4320-case gate, 12 probes, bad-length and mutant markers, independent Git/ZIP/output audit. Stage18 remains last accepted, Stage19 NOT_ACCEPTED. Pointer safety outside bounded contract; no main/merge.
