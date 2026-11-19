# Stage49 / DISCOVERY45 — four-live-output isolation across caller-input reinitialization
PROJECT_ID: PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
Branch: COBOL+简体中文
Prerequisite: Stage48 accepted at exact SHA 9413a74c17faaf302e4a922cddf40e2ae31b3600 (49/49 jobs, measured heap zero).
Evidence: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44392104589
Kind: bounded test-only DISCOVERY; no historic defect asserted; no production source changes.

## Rationale and question
Stage39 already tested input lifetime with fewer simultaneous outputs; Stage48 tested four occupied output destinations across rolling reuse without explicitly replacing both caller inputs while four outputs live. The next independent question is whether four currently owned results remain valid if both caller-owned arbitrary-precision input objects are released and reinitialized with different values, and whether one output can then be replaced using the new input pair while three old outputs remain unchanged. The oracle is independent of COBOL and cannot confer Native acceptance.

## Deterministic input and output contract
For n in {3,9,320,8192} and j=1..6, set X=10^(n-1)+(5j+2), Y=10^(n-1)-(2j+5). For odd j use C=X,T=Y, otherwise C=Y,T=X. Sign s=+1 for odd j, -1 for even j.
Produce four distinct caller-owned output descriptors, slot k=1..4, with C_k=C+s(k-1), T fixed. The expected decimal result for each is |T-C_k|+1 = 7j+8+(k-1).
While all four outputs remain live, release BOTH caller-owned input objects through the accepted BIG-INTEGER-SERVICE release route, in alternating order by j parity; initialize them afresh via INIT-TEXT to C'=C+s(10j+3), T'=T-s(10j+3). Preserve the original output values and descriptors across input destruction and reconstruction. Re-check four result values/ownership and both new inputs. No mutation of a live output may be accepted.
Select a slot k = (((width_index*6)+(j-1)) mod 4)+1 with width_index=0..3. Each slot is selected exactly six times. Release only that output slot; check the other three survivors are unchanged and independent. Create a NEW output in that freed slot from C'_k=C'+s(k-1) and T'. Expected output = |T'-C'_k|+1 = 27j+14+(k-1), and the other three outputs must retain their OLD expected decimal values. Old and replacement output descriptors must not share the same live owned allocation.
Restore inputs to C,T using the same release/reinitialize route (reverse release order), retire ONLY the replacement result, and rebuild the original selected output, checking all four original outputs. Finally release every output and both inputs and measure HEAP-LIVE=0. All success and failure paths must clean up. Never call release on an already released pointer.

## Bounds, model and quality gates
24 deterministic distinct (C,T) pairs, 6 at n=8192; 96 original and 96 mutated BigInt/closed-form arithmetic comparisons (192 total). The standalone planning model in test/stage49_planning_oracle.mjs asserts 96 input release/rebuild events across the two input cycles, 96 preserved results after input changes, 72 survivors after one output free, 72 survivors after new output creation, 24 new output owners, 24 restored output owners, and slot balance 6/6/6/6. Planning model output must be PASS_NOT_NATIVE.
Implement isolated test/stage49_discovery_tests.cob using source interfaces already accepted in THIS branch; no copying from other language branches. Native result must check exact numeric output strings, output descriptors and snapshot invariants, status codes, both input snapshots, 24 cases passed, unexpected=0, measured heap=0. Do not treat a planning-model PASS as Native PASS. Do not mark an expected-red until a real native failure is reproduced.
Wire one new strict GnuCOBOL 3.1.2 -Werror CI job after 48, with compile timeout <=300 s, execution <=120 s, job <=20 min, and upload of raw evidence. Require 50/50 completed/success (49 prior jobs + Stage49), exact source HEAD, source-oracle markers, Native counters, artifact SHA256 and ZIP CRC before accepting Stage49. Respect existing source width constraints and strict compile; regression jobs must remain intact.

## Stage49 status at plan commit
CONTRACT_AND_INDEPENDENT_PLANNING_ORACLE_ONLY; NO COBOL HARNESS; NO STAGE49 NATIVE RUN; NOT ACCEPTED.
NEXT: implement the bounded Stage49 COBOL test harness and CI from this contract, static-check emitted source literals against independent BigInt and closed form, push to the existing COBOL+简体中文 branch, then assess completed exact-SHA logs and artifact. No main, merge, release, or claim of full calendar integration.
