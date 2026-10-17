# QA spaghetti04 — second revision: genuinely causal two-armed scanner branch

Production: unchanged; three previous QA executable gates preserved.
New candidate Git blob: 2120c61485ae196dc387e617d3cff69a272bc413
Stage03 parent: 2baa1795a9a5802f58ecbd87ac8f138a1e811066
Stage04 initial Native-failed blob: e2eb7eec5503c22c6e73fb66aa7f8b9b072c4667
Stage04 intermediate candidate: 49492b73ee5ef4a637a55da5283d53023249b989

First Native run 39028111607 established actual, input-sensitive two-way
| branch: initial digit 0 selected lower arm, initial digit 1 upper arm,
both arms rejoined (320,7) and returned to scanner at (109,5); original
and candidate outputs matched all six input cases. That first Native
run FAILED the causal gate: south 0 -> 1 was output/termination inert.
This failure and original candidate are kept for provenance.

Revision 2 connects the arm-produced zero directly to the motion vector
at the common westward return lane using the executed sequence :1-0x.
The original zero makes dynamic velocity (-1,0); corrupting it changes
velocity and therefore which cells are executed. The upper arm has
been rearranged to compute its final zero using live instructions
0 0 0 + 1 - !, so changing the arithmetic affects that same vector.
Both ordinary arms still produce the initial scanner byte followed by
two zeros and should rejoin their original execution path.

Compared with Stage03 there are exactly 33 modified Funge-space source cells.
The exact-head Native test now demands separate actual upper/lower route
witnesses, production/parent/candidate parity, three independent Befunge
reference programs for four valid cases, invalid token parity for two,
and four controlled counterfactual changes spanning lower arm, upper
arithmetic, upper operand and dynamic rejoin velocity. A timeout from
a changed IP is causality, not a normally terminating numeric answer.

Stage1 OPEN; Last completed stage 0; Stage2 NOT STARTED.
No production promotion or PR merge; final state/reentrancy acceptance
and full Native legacy regression are still separately pending.
