# SM83 Stage1: bounded adjacent-year transition Native329–340

Project ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Parent accepted SHA: 8f1a0ca39df6a67731a31d023aac423f8ee00fb8

## Exact contract

This is a genuine SM83 ROMX transition, **not** a c-dependent gate generator
or a seal 10/11/12 chooser. Calling code supplies independently derived
`proposedOpen,proposedClose` signed32 gates for a NEXT or PREVIOUS candidate.
The current gate interval is `(currentOpen,currentClose]`, with an unsigned16
year number. `wCalendarYearDirection` is 1 for NEXT, 2 for PREVIOUS.

On an active invocation with canonical owner ordinal, it verifies:
1. NEXT: proposedOpen equals currentClose; PREVIOUS: proposedClose equals currentOpen.
2. Signed32 ordering proposedOpen < proposedClose.
3. 252 <= proposedClose-proposedOpen <= 5778, using all 32 difference bits.
4. Unsigned16 year increment/decrement does not roll over.

Status=0 atomically updates only current span and year candidate; leaves
projected year output, owner/lease tags and SRAM payload untouched.
Status=2 on invalid input, status=6 when idle; both preserve current span,
year candidate and output. Scratch WRAM and SRAM selection can change. The
calculation ordinal `c` is not an input to this kernel. No claim of computed
normative gate positions or year selection is made.

## Evidence gates

Independent host oracle uses Python integers, 11 synthetic calls, 10 extra
edge/rollover cases, and 12 dynamic transitions on three distinct calculation
days. Native cases 329..340 cover idle, valid next/previous, broken adjacency,
251/5779-day rejection, invalid direction/ordinal, year overflow/underflow,
read-only SRAM/tag sentinel and abort scrub. The synthetic gates are *not*
claimed to be the normative selected gates for seal 11/12.

Require both natural-push CI jobs completed/success on exact commit SHA:
HOST_STAGE1_YEAR_STEP_ABI PASS, RGBDS/ROM_HEADER PASS, ROM0 free>=10,
PyBoy A5/LAST_TEST_CASE=340/DISPATCH_STATUS=40, frames<=9000. A queued
job is not PASS.

## Remaining Stage1

Still needed: real SM83 c-dependent gate generation and seal 10/11/12 choice;
wire their independently validated candidates to this transition and known
span projection; general arbitrary-length ordinals; all five Native date fields;
independently reviewed Ge'ez source name catalog. No production dispatcher
activation, main changes, merge, publication or Stage2.
