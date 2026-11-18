# SM83 Stage1: Native short Equal Selection rank kernel (341–357)

Project ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Parent accepted SHA: 3dd5d04361f29fab9b26c5fc3ae76ce7d0e1c8e9

## Contract

This is a real SM83 ROMX kernel for the short Equal Selection mechanism. It is the rank primitive needed by gate-gap selection and by the year-5000, NEXT11 and PREVIOUS12 candidate selectors. It does not generate sauce, bowl answer flows, gates, or candidate lists.

Inputs:
- A0: canonical positive SAVE residue in the fixed 16-byte little-endian ABI, 1 <= A0 <= M.
- N: unsigned 16-bit candidate count, 1 <= N <= 19044.
- direction: 1 for forward (+1), 2 for backward (-1).
- An active canonical ordinal lease, validated read-only before computation.

Outputs:
- status 0 and exact unsigned 16-bit rank in 1..N.
- status 2 for invalid input; the previous rank remains unchanged.
- status 6 for an inactive invocation; the previous rank remains unchanged.

The input residue, count, direction, ordinal, owner/lease tags and SRAM payload are read-only. Scratch WRAM may change. The kernel does not activate the production dispatcher.

## Mathematical reduction

M = 2^127 - 1
L = floor(M/N) * N = M - (M mod N)

If A0 > L, the rejected tail is traversed in the prescribed direction:
- forward (+1) wraps to the first accepted value, so rank = 1;
- backward (-1) reaches L first, and because L is divisible by N, rank = N.

Otherwise:
rank = 1 + ((A0 - 1) mod N).

The implementation computes A0 mod N and M mod N with the bit recurrence r <- (2*r + bit) mod N. Before reduction, r < N and therefore 2*r+bit < 2*N. Since N <= 19044, the temporary value is below 38088 and fits in 16 bits; one conditional subtraction is sufficient per bit. The kernel scans exactly 127 bits for each remainder, constructs L, and compares A0 with L.

## Proven candidate-count bound

The minimum adjacent-gate gap is 42 days and the maximum year span is 5778 days. Each side of a year-5000 candidate interval can therefore contain at most floor(5778/42)+1 = 138 gate positions. Section Q's candidate-pair count is at most 138*138 = 19044. NEXT11 and PREVIOUS12 have at most 138 candidates each. Section O's gate-gap selection uses N=922. Thus all these short selections fit the kernel's N bound and are far below M.

## Evidence

Native cases 341–357 cover idle preservation, invalid N/direction/A0, N=1, forward and backward rejected tails, exact L boundaries, N=922, the 19044 maximum, input preservation, owner/lease preservation, and abort scrub.

The independent Host oracle uses Python integers and source-derived sauce/selection calculations for three distinct calculation days. It checks all three seals 10, 11 and 12 (nine c-dependent choices), plus synthetic and boundary matrices. Host-derived c-dependent inputs are not represented as Native execution.

Acceptance requires both natural-push CI jobs completed/success on the exact commit SHA, HOST_STAGE1_SHORT_SELECT_ABI PASS, RGBDS/ROM_HEADER PASS, ROM0 free >= 10, PyBoy A5/LAST_TEST_CASE=357/DISPATCH_STATUS=40, and frames <= 9000.

## Remaining Stage1

Still missing: native sauce E–K and bowl-answer-flow generation from c/t; native c-dependent gate-gap generation; candidate enumeration and wiring the seal 10/11/12 ranks into actual year spans; arbitrary-length ordinal support; all five Native date fields; independent review of the Ge'ez source-name catalog. The bounded year-step kernel remains a separate transition verifier. The production dispatcher remains $40. No main change, merge, publication or Stage2.
