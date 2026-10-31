# Stage 12 / DISCOVERY09 — నిజమైన సాస్ పై కుండ ప్రశ్నలకు స్వతంత్ర సంఖ్యాత్మక పరీక్ష

## Previous gate
Stage11 native [Actions 41196519882](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196519882) completed/success on 5db0a575044254df2c3a63a50e904fe3320a8e32: 12/12 jobs, verify success, GNAT13 compile/bind/link and STAGE11_DISCOVERY08_ASSERTIONS= 368 in job 124523671270. The previous acceptance covers the seven-cell FIFO visible-drop recurrence only.

## Independent Stage12 contract
Inputs: eight literal (calculation day, target day) pairs, identical to the bounded Stage11 date domain, chosen to cover same, neighboring, reverse and distant days. For each pair invoke the real Sauce once; query all six bowl IDs using the four literal seals 0, 1, 193 and 1,000,003. There are 8 × 6 × 4 = 192 actual streams.

For every real Sauce_Result, derive the expected first answer independently from its six final bowl residues and the six-item last-drop ordering. Locate the next bowl by a forward ring lookup, not the production Wrap_1 helper. Compute the two squarings via ordinary Big_Integer multiplication and 1-based modular projection R(x) = 1 + ((x-1) mod M), M = 2^127−1. The next-bowl coefficient is 179, the fixed first seed is 181, the second seed adds 194, the second residue adds 193×First and 197×Bowl(6), and parity selects ±1. No production Ask_Bowl, Answer_At, Save or Square calls produce expected values.

For each of 192 streams compare exact First, exact Direction_Step, and five separately calculated Answer_At values at K=0,1,M,M+1,2M+9. Each residue comparison also enforces [1,M] and step comparison enforces ±1; diagnostics print pair, bowl, seal index, sample, expected and observed decimals. **Exactly 8×6×4×(2+5)=1,344 assertions**; expected marker STAGE12_DISCOVERY09_ASSERTIONS= 1344.

## Limits and acceptance
This is a bounded direct numerical differential for *real Sauce→Ask_Bowl→Answer_At* that extends Stage7's stream metamorphic properties and Stage6's synthetic first/direction checks. It still consumes production Sauce_Result and does not independently prove the entire Sauce, Calendar_Date or the five final calendar fields. No other-language fixture or implementation used. No production change.

Ubuntu 24.04, GNAT 13, 15-minute bounded job native-stage12-discovery09 running sh ./run_stage12_discovery09.sh. Accept only after both verify and this native job complete successfully on the same commit and the log shows compile/bind/link and the exact marker 1344. A pending run is neither a blocker nor PASS. A PATCH requires an observed reproducible failure, not a conjecture. No main/merge/publish.
