# Stage 10 / DISCOVERY07 — రాళ్లు మరియు దాచిన చుక్కల స్వతంత్ర లెక్కింపు

## Previous gate
Stage9 [Actions 41193150492](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193150492) completed/success, 10/10 jobs on SHA 247e49e957bd225c5547fc90ac7e8c3407feb6bc, GNAT13 compile/bind/link and 106 assertions. Stage9 accepted only for its bounded bowl-mixing differential.

## Independent input/output contract
Eight literal date pairs (the Stage9 coverage including near/far and reverse direction) are used to check five Work_Count fields and seven hidden-drop values per pair. Also compare all five stone fields of each of 46 indexed stones exactly once. The reference uses a separately coded arithmetic recurrence, direct Big_Integer multiplication and modular reduction, not the production Day_Count, Build_Stones, Build_Hidden_Drops, Save or Square functions. Coefficients are literal normative formulas from this branch, not code/fixtures copied from other language branches.

Expected assertion count: 46 x 5 + 8 x (5 + 7) = **326**. The marker is STAGE10_DISCOVERY07_ASSERTIONS= 326. Each mismatch prints pair index, slot, expected and observed decimal Big_Integer. Test-only scope: this does not validate 46 visible-drop recurrences, Sauce as a whole, Calendar_Date, or the semantics of normative constants independently of the written specification. No production change.

## Gate
Ubuntu 24.04 GNAT 13, bounded job native-stage10-discovery07 with 15-minute timeout and sh ./run_stage10_discovery07.sh. Accept only if verify and native-stage10-discovery07 both completed/success at identical HEAD with GNAT compile/bind/link and marker 326. A queued/in_progress run is neither PASS nor blocker. Log any actual mismatch before PATCH. No main/merge/publish; native CI available, so no user-run package.
