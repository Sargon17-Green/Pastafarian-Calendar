# ዜና ዘመን — stage ledger

| Stage | Kind | Status | Note |
|---|---|---|---|
| 1 | BOOTSTRAP | IN_PROGRESS | SM83 exact primitives, 80 native ROM smoke cases, scratch-bank leases; normative calendar still absent |
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
tests 41..52. The historical 55-stage route is unchanged. Native QA passed in
GitHub Actions run 38691700266 (52/52 ROM cases); Stage 1 remains open.

## Candidate: exact signed SRAM sum

Added a fixed-capacity `SignedAdd4096` primitive, using existing unsigned
addition/subtraction/compare and a reversed subtraction path for cases in
which |B|>|A|. Invalid signed encodings fail closed. Native ROM cases
53..66 passed native CI in run 38781963706 and remain a bootstrap subset only. Stage 1 remains IN_PROGRESS until
the normative calendar and full source-language catalog are independently
verified.

## Stage 1 scratch SRAM bank leases — candidate

A separate MBC5-native scratch allocator leases 13 SRAM banks after
reserving banks 0..2 for existing arithmetic. The 14 ROM cases 67..80 passed natively in Actions run 38788682300. This is not the final semantic-state owner or
unrestricted BigInt allocator; no historical discovery/patch work starts.
