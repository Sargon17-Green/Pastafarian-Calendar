# Stage56 B5 — PHP production bowl selection beyond five digits

PROJECT_ID: PC-BRANCH-PHP-MALAY
Branch: PHP+Bahasa-Melayu
Parent SHA: 40a603424d16b7b7796c6a7881b1efb453082f3c
Scope: opt-in independent production arithmetic, not a new stage or PATCH22/PATCH23 integration.

## Reason for this change

Existing BootstrapKernel::chooseQuintRank covers M^4 < n <= M^5, where
M=170141183460469231731687303715884105727. A genuine weave universe
can exceed M^5. A source-authenticated PHP year provider cannot use a
truncated/uniform-modulo shortcut when such a rank is needed.

## Precise contract

Input: a positive BigInt N, calculationJdn c, targetJdn t, bowl ID 1..6,
seal, and the exact canonical BootstrapKernel::askBowl response for (c,t,
bowl,seal), (first in 1..M, direction +1 or -1).
Output: an unbiased one-based rank in 1..N, preserving the source stream.

For N<=M, the acceptance limit is floor(M/N)*N. For N>M, choose the
smallest k such that M^k>=N, use k consecutive 1..M responses, least
significant digit first after subtracting one, and let the wide number
range in 1..M^k. Use limit=floor(M^k/N)*N. If first proposed wide number
is above that limit, the normatively defined circular +/-1 walk has a
closed-form first accepted point: 1 for positive direction, limit for
negative direction. This is an exact skip over rejected values, not
immediate modulo-bias or a re-seeded stream. The returned rank is
1+((accepted-1) mod N), entirely in production BigInt.

No time-dependent input or hidden source/oracle substitution is used.
PHP source uses BootstrapKernel::askBowl (production sauce and authentic
drop-46 bowl neighbor). The independent test oracle is required only by
tests/stage56_unbounded_choice.php; production imports neither test
code nor oracle fixtures.

## Gate and limitations

Local or Native execution must verify the code and test at an identical
SHA before accepting the new bounded selection component. The added
workflow records PHP 8.3, 64-bit, lint, stdout, stderr, exit status and
SHA-bound artifact, with a 900s timeout and 512M PHP memory limit.

This does NOT construct Year5000, authenticate the external source commit
or calculationJdn, generate cutlet/month/year records, verify 4999/5000/
5001 exports, perform three real-year profiles, or accept Stage56.
No merges, main edits, publication or PATCH22/PATCH23 wiring.
