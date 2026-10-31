# Stage 1 QA Spaghetti05 — shared-history memory stamp and polynomial rendezvous

Scope: `qa-befunge98-stage1-order-isolation-20261008` only. Production, Stage 2 and PR #17 untouched.
Parent QA04 Git blob `2120c61485ae196dc387e617d3cff69a272bc413`;
new QA05 Git blob `59917c4c73be687bfe80b03818e38ad9c3a97243`. Exactly 19 source-cell changes, all in
three existing travel rows (5, 7 and 9).

Upper branch writes 1 to physical Funge-space (9,9) via west-executed
`p991` at (342..345,5). Lower branch writes 2 to precisely the same
cell via `p992` at (340..343,9). This is a genuine dynamic state owner
for the two alternative input-parity routes, not decorative line drawing.
After rejoining at (320,7), the westbound common lane reads that same
cell with native `g` and evaluates the polynomial

`(stamp-1)*(stamp-2)-1`

using native code `99g:1-\2-*1-0x` (stored in reverse, at (190..203,7)).
Both legitimate stamp values produce IP velocity (-1,0) while retaining
the two input scanner stack zeros; corrupted stamps alter the live
instruction-pointer successor or termination.

The source-pinned QA05 workflow runs PyFunge-98 with physical write/read
traces. Acceptance demands actual fork, single write to (9,9) before join,
read after join before native x, matching values and exact tick ordering,
native post-x successor, scanner reentry, production/QA04/QA05 parity for
4 valid plus 2 invalid tokens, and independent triple-Befunge reference
comparison of all 4 valid cases. Five localized mutations target both
distinct writers, write suppression, read suppression and polynomial
multiplication. Mutants record final/termination changes independently
from changes in IP motion. All traces and receipts are retained even on
failure.

Stage 1 remains OPEN, LAST_COMPLETED_STAGE=0. No candidate promotion to
src/ and no Stage 2. Native verification must not be reported as PASS
unless GitHub Actions concludes successfully on an exact source-pinned
HEAD. Historical QA03/QA04 and failure specimens stay in the repository.

## First native iteration — preserved failure evidence

Run 39031159000 on HEAD 6182fea3 failed in the QA trace checker, not
in production/native output parity. PyFunge's STEP hook visits *executed*
nonblank instructions: following x at (190,7) with direction (-1,0),
the next recorded executed instruction is the scanner return arrow at
(109,7), not the adjacent empty space (189,7). The initial checker
incorrectly expected (189,7,-1,0); corrected expectation now verifies
(109,7,-1,0). The original failed workflow and its artifact remain.
