# ዜና ዘመን — stage ledger

| Stage | Kind | Status | Note |
|---|---|---|---|
| 1 | BOOTSTRAP | IN_PROGRESS | SM83 entry, exact 128-bit SAVE primitive, ten native arithmetic checks |
| 2 | DISCOVERY_01 | NOT_STARTED | Must preserve intentional historical wrong behavior |
| 3 | PATCH_01 | NOT_STARTED | Must retain Stage 2 scar as diagnostic copy |
| 4..53 | DISCOVERY/PATCH | NOT_STARTED | 25 further discovery/patch pairs |
| 54 | FINAL_INTEGRATION | NOT_STARTED | Historical live routes, no shortcuts |
| 55 | FINAL_AUDIT | NOT_STARTED | Native hardware/emulator and independent differential verification |

No code from another programming-language branch has been copied into the
SM83 production runtime. No future stage is marked complete or bypassed.

## Candidate extension — 4096-byte magnitude comparison

The unsigned, fixed-capacity SRAM compare subroutine was added alongside
seven new native tests (cases 34..40). No calendar semantic stage has been
marked complete, and the 40-case smoke subset passed native CI (run 38686711132).

## Signed comparison candidate

Stage 1 extension adds canonical signed-magnitude comparison plus ROM
tests 41..52. The historical 55-stage route is unchanged. Native QA
for this candidate is pending; Stage 1 remains open.
