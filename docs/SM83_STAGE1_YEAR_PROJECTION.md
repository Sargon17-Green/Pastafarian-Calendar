# SM83 Stage1: bounded Native known-year projection (320–328)

Project ID: PC-BRANCH-SM83-ASSEMBLY-GEEZ
Branch: SM83-Assembly+ግዕዝ
Parent accepted SHA: 881b4ede531eb8c96f2d5c63d5ad3d45492be277

## Exact incremental contract
This is a real read-only SM83 ROMX kernel for an ALREADY DERIVED year
interval. It is NOT a gate generator, a chooser among candidate years, a
general arbitrary-magnitude date converter, or proof of Stage1 completion.

Input: active serialized owner (DI, enabled SRAM, valid lease); canonical
little-endian signed-magnitude target ordinal (zero: sign0/length0);
two independently generated two's-complement signed32 gates and unsigned16
candidate year in WRAM. Span is supplied by the calling stage, which must
verify its legality and provenance. Current kernel supports signed32 target
[-2147483648, 2147483647]; all other magnitudes fail closed.

Output: if open < target <= close, status=0 and candidate year copied to
separate output; otherwise status=2 and output unchanged. Inactive invocation
returns 6. No SRAM contents, lease ownership/tags, or target ordinal metadata
are written. Scratch WRAM and SRAM bank selection may change. This routine
does not itself prove year span length 252..5778 or the 5000-year selection.

## Independent evidence and gate
Host suite: dynamically obtain each of the ten canonical c,t year spans
using the accepted year-path algorithm; use separate Python-int sign/magnitude
decode and signed32 comparisons to check 10 canonical years, 40 exact
half-open edges, plus malformed representations. Expected AC.1 year numbers
are assertions only. Native320..328 independently checks real SM83:
idle/valid Foundation membership/open/open+1/close/close+1/negative zero/
positive 32-bit overflow/owner abort scrub.

Acceptance requires the natural push CI at this exact HEAD with BOTH
verify and dmg-native-smoke jobs completed/success; real RGBDS compilation,
ROM_HEADER PASS, ROM0 measured free >=10, PyBoy status A5,
LAST_TEST_CASE=328, dispatcher=$40, frames<=9000 and Host marker PASS.
Before completion this is a candidate, not accepted Native functionality.

## NEXT after acceptance
Supply validated ordered year spans derived from the c-dependent gate and
year5000/NEXT11/PREVIOUS12 selection algorithms to this bounded kernel; add
Native tests for c-dependent forward/backward selection and a broader
signed ordinal comparison before connecting any production dispatcher.
Canonical Ge'ez name catalog and five-field Native calendar remain open.
No main change, merge, publication, or Stage2.
