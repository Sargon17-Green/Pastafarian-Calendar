# Stage 6 / DISCOVERY03 — కుండ క్రమం మరియు సమాధాన ప్రవాహం మూల పరిశీలన

## Independent choice and source boundary

Stage5 PATCH02 accepted only the test-only short-route fix on commit `8f33b8e0dc1fae6fe61e0d64f9b6c2c80431e14b`, run [41137003539](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41137003539), 6/6 completed/success, GNAT 13 compile/bind/link and 1,465 assertions. Stage6 is a **new, independent source survey** of `Normative_Oracle.Ask_Bowl` (src/normative_oracle.adb, lines 375–402) and `Answer_At`; it does not re-test rank rejection loops as a new defect. Neither the legacy algorithm nor production is changed.

## Fixed bounded test contract

Input: For each `Order_Number = 1..720`, obtain a distinct six-position `Bowl_Order_From_Number` and construct one synthetic `Sauce_Result` with deterministic low/high Big_Integer bowl values. Verify that all six IDs occur exactly once (one assertion per order). For each queried bowl ID 1..6 and seal in {0, 1, 193}, query `Ask_Bowl` and calculate three **separate** expected properties without calling `Save`, `Ask_Bowl` or `Answer_At` in the reference calculation:

* Cyclic next-bowl lookup by explicit independent search through the order and `1 + (position mod 6)`.
* `Expected_First = 1 + (([(Bowl[id]+seal+181)^2 + 179*Bowl[next]+seal] - 1) mod M)`, `M=2^127-1`.
* `Expected_Direction = 1` exactly when `1+(([Expected_First+seal+194]^2+193*Expected_First+197*Bowl[6]-1) mod M)` is odd, otherwise -1.
* One-step stream expectation is `1+((Expected_First-1+Expected_Direction) mod M)`.

Check the actual first value, direction and `Answer_At(stream,1)` (three assertions per stream). This is `720*6*3=12,960` synthetic stream cases, `38,880` property checks, plus `720` permutation checks. One deliberately malformed order omitting a queried ID must yield `Constraint_Error` and is a **domain-boundary control**, not a discovered calendar bug. Total: `39,601` assertions. Test data are synthetic and not asserted reachable from real `Sauce`.

## Scope and honest negative evidence

The source constrains `Answer_Stream.Direction_Step` to +/-1 from `Ask_Bowl` and normalizes First through `Save`. Passing the test only establishes the explicitly bounded synthetic properties, not total correctness or the five-field date output. A failure must be reproduced with input, expected/observed value and GNAT log before naming any defect. Invalid duplicated order values may trigger Ada bounds checks, not a presumed infinite loop. Do not invent historical expected-red evidence.

## Reproducible acceptance gate

Run `sh ./run_stage06_discovery03.sh` with GNAT Ada 2022. Job `native-stage06-discovery03` on `Ada+తెలుగు` has a 15-minute CI bound. Accept Stage6 only after **both** `verify` and the Stage6 Native job are completed/success on the same commit, including compile/bind/link, and the log contains `STAGE06_DISCOVERY03_ASSERTIONS= 39601`. Run queued/in_progress is not PASS and not a blocker. Do not modify main or production.
