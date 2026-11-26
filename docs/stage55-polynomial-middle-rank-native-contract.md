# Stage55 — full middle-rank native differential for the polynomial candidate

**Project:** \`PC-BRANCH-MATLAB-POLSKI\`  
**Scope:** test-only MATLAB R2026a verification of \`pastafari.WholeMonthWeavingFamilyPolynomial\`. This does not change or invoke the production month-weaving route and does not accept Stage55.

## Inputs and independent references

- \`tests/fixtures/stage55_year5000_appendix_a_metadata.json\`: exact 45 month lengths, 4,244 days, minimum 25 and maximum 122. The source-rank / cutlet / Polish-catalog oracle independently rederived this vector and matched the fixture (run \`45691066424\`, commit \`fefba6186f086bd011d2a18b26b6cbbabd385f83\`).
- \`tests/fixtures/stage55_year5000_middle_word.json\`: the complete 4,244-symbol word. The independent C++17/GMP verifier checked all 4,244 nested prefix intervals, the exact root count, the one-based middle rank and the singleton terminal interval (run \`45686680226\`, verifier commit \`7b37e6a74b351e10e6e229dba5bbd0d7438c458a\`).
- Expected root-count SHA-256: \`c0c08ac89c8faaaf589d1b3e076fe1e96405f2ad7172a15efa9d028fb43fb6f8\`.
- Expected middle-rank SHA-256: \`cd5ce4036fc8e99355a4bab5d48c3db473422083d035df5e0af25297be1be3b6\`.
- Expected word SHA-256: \`82042fef5a65cc8b08120d069fa9d8f31c05e6761040f82c3341328ded9b44e5\`.

## Measurable contract

1. Read only the two pinned Year-5000 fixtures; assert 45 positive month lengths summing to 4,244 and a 4,244-symbol comparison word.
2. Instantiate \`WholeMonthWeavingFamilyPolynomial\`, compute its exact total \(T\), and require the expected 6,765 decimal digits.
3. Compute \(R=\lfloor T/2\rfloor+1\), require 6,764 decimal digits, and write the exact decimal strings to retained evidence files.
4. Generate the complete word with \`WholeMonthWeavingFamilyPolynomial.itemAt1(R)\`.
5. Require exact equality with the independently verified C++/GMP word, all 45 multiplicities, strictly increasing first occurrences and strictly increasing last occurrences.
6. Verify the exact total and rank SHA-256 values in the workflow. Preserve the MATLAB log, count, rank, generated word and report on both PASS and FAIL.

Bounds: exact count ≤240 seconds; full middle-rank unrank ≤2,400 seconds; GitHub job timeout 55 minutes. No state truncation, sampling, skipped suffixes or floating-point counting is permitted.

## Explicit non-claims

- \`WholeMonthWeavingFamilyPolynomial\` is experimental; it is not the current production \`WholeMonthWeavingFamily\`.
- The test does not call \`MonthWeavingDPPatchWrapper\`, \`MonthWeavingCompatibilityRoute\`, \`finalMonsterIntegration\` or \`normative_oracle\`.
- A PASS would establish a native MATLAB differential for the candidate algorithm only. It would not establish the current production path, the final five-field calendar result, or Stage55 acceptance.
- \`LAST_COMPLETED_STAGE\` remains 54 until the actual production route passes the complete Stage55 native audit.

## Why this candidate gate is needed

The current production \`WholeMonthWeavingFamily.buildExactStateDP\` materializes every reachable remaining-vector state. In the first 24 positions of the pinned year, no month can close and each of the first 24 month lengths exceeds 24. The number of distinct states after \(d\) positions is therefore exactly

\[
\sum_{k=1}^{d}\binom{d-1}{k-1}=2^{d-1}.
\]

The native production audit observed 32,768 states at day 16, matching this count. The same construction gives 8,388,608 states at day 24. The candidate test isolates whether the existing polynomial/endpoint implementation can produce the independently certified complete middle word without modifying production.

## NEXT

After this candidate gate, the remaining decision is whether to authorize replacing the exponential production month-weaving DP with the independently exercised polynomial/adjoint algorithm, followed by the unchanged full production-vs-oracle Stage54/55 audit. Until that production integration is authorized and passes, Stage55 remains open.
