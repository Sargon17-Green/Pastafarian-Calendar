# INT-02 gap composition ABI — implementation candidate
Project PC-BRANCH-COBOL-SIMPLIFIED-CHINESE. Parent a266e9ae697b7dd7153e2da5373605000bdac449.
CALENDAR-GAP-COMPOSITION(op, R, K, G, rank-in, vector-in, result, vector-out, status).
All parameters by reference; op X, R/K/G/status unsigned binary-short, vectors 17 unsigned binary-short entries, handles as BIG-INTEGER-SERVICE ABI. Inputs and outputs must be distinct, output handle empty on entry. C returns count; R returns one-based rank for a vector with zero unused entries; U returns vector with zero unused entries. Rank-in used only by U; vector-in used only by R. Status 22 invalid domain, rank or vector; service status propagated. Error outputs empty; caller frees nonzero result with FREE-A. No scratch handle allocated; sole exported handle has ordinary caller ownership or belongs to active caller scope. No shared arithmetic changed.
Pascal table 137*17*30 bytes = 69,870 bytes (display decimal). For p positive parts of r with a fixed interior cut, count C(r-2,p-2) follows by choosing the remaining p-2 cuts; independent differential uses the earlier sum-of-products formula. Max C(136,16) fits 21 digits. No rank >21 digits is serialized except bounded 3 chunks <=27 digits for rejection. No Native acceptance claim.
Targeted commands (GnuCOBOL, from repository root):
```sh
cobc -free -x -o int02-gap-composition test/int02_gap_composition_driver.cob src/calendar_gap_composition.cob src/big_integer.cob
node test/int02_gap_composition_diff.mjs ./int02-gap-composition
```
Only this new gate; do not rerun six accepted gates. Pending Native compile and differential. Other three composition/selection/weaving modules remain open.
