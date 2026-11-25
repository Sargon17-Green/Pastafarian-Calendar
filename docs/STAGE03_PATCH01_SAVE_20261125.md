# Stage 03 — PATCH 01: REMAINDER_SAVE

PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE  
Branch: Object-Pascal+Português  
Base HEAD: 7159dda6a874ebc2e9b00fe6e3ce696290452c0d  
Previous accepted stage: Stage02 DISCOVERY01 on exact tested code SHA c9bd7243924efee710cb9437bacc5971027d190d.  
Contract status: ACCEPTED on exact tested code SHA 43add99d816cc0a8b5feb17df3e76935957e5a90. Stage01, Stage02, Stage03 Native, and Canonical Names Lock all completed successfully on that exact SHA.

## 1. Normative contract

The frozen normative source is README.md at main@56bc4173aae4975ded019ef5ab5a36249f1424df, Section D:

~~~text
M = 2^127 - 1
SAVE(x) = 1 + ((x - 1) mod M)
~~~

For every signed arbitrary-precision integer x, SAVE(x) must be an integer in 1..M. The remainder is Euclidean because M is positive.

Required examples:

| Input | Expected SAVE |
|---:|---:|
| 0 | M |
| 1 | 1 |
| M | M |
| 2M | M |
| M+1 | 1 |
| -1 | M-1 |
| -M | M |

Equivalent implementation identity:

~~~text
SAVE(x) = BigRegularModPositive(x - 1, M) + 1
~~~

BigRegularModPositive remains the legacy ordinary-remainder primitive. Its contract and implementation are not changed: for positive divisor M, its result is in 0..M-1. The distinction is intentional: the two functions differ exactly when x is divisible by M, where ordinary remainder returns 0 and SAVE returns M.

## 2. Production change

src/BigInt.pas exports BigSave(const A: TBigInt): TBigInt.

- The production function uses the fixed normative modulus 170141183460469231731687303715884105727.
- It subtracts one from the arbitrary-precision input, calls the retained BigRegularModPositive, then adds one.
- It supports negative, zero, positive, and values wider than 127 bits.
- The existing BigRegularModPositive body is preserved byte-for-byte.
- Test-only NormativeOracle.NormativeSave remains an independent implementation; it is not used by production code or imported by the new Python oracle.

No other production algorithm, language catalog, normative source, or stage policy is changed.

## 3. Independent differential oracle

docs/stage03_save_oracle.py uses Python arbitrary-precision integers only. It imports no Pascal implementation and consumes no cross-branch fixtures.

It emits 128 unique signed inputs:
- Hand-selected normative boundaries around 0, ±1, ±M, ±2M, and 16M.
- Three values kM-1, kM, kM+1 for each k=-8..7, with duplicate values removed.
- Deterministic signed values of widths from 128 through 2047 bits, generated from seed 0x535441474533 until the vector count reaches 128.

Each row contains the input, M, the ordinary legacy remainder, normative SAVE, and a classification derived from the two independent Python expressions. The oracle verifies uniqueness, byte-exact TSV reproduction, result range, periodicity under x±M, and the legacy/SAVE divergence condition.

Expected distribution:
- 17 EXPECTED_RED rows (exact multiples of M, including the 16M boundary).
- 111 MATCH rows.
- 128 unique input rows.

Expected UTF-8 TSV SHA-256:

f011be78e4e6fe8489f8ae4f1e5040c0c161e6376db8b4d7c38e15d86b5b0017

## 4. Native Pascal regression

test/stage03_save_regression.pas consumes the Python-generated TSV and, for every row:

1. Checks the row shape, uniqueness, and normative modulus.
2. Calls the real production BigRegularModPositive and compares it with the independent ordinary-remainder column.
3. Calls the new production BigSave and compares it with the independent SAVE column.
4. Checks the legacy result range 0..M-1 and SAVE range 1..M.
5. Checks the expected classification.
6. Checks SAVE(x+M)=SAVE(x) and SAVE(x-M)=SAVE(x).

The expected total is 1,541 assertions, 128 rows, 17 expected divergences, 111 matching controls, and zero failures.

test/build_and_run_stage03_save.sh records separate oracle, compiler-version, compile, suite, and aggregate exit markers. It pins FPC 3.2.2, TSV SHA-256, and the required summary markers. The Native workflow uploads both the complete log and the exact TSV.

## 5. Exact-SHA acceptance gates

The new Stage03 workflow runs the independent Python oracle and Native Pascal suite. The existing push workflows are also expected to run naturally on the same source SHA because src/BigInt.pas changed:

- Stage01: complete existing regression suite and Portuguese UTF-8 checks.
- Stage02: WorkCounts, Context, Lifecycle, and Discovery01 regression.
- Canonical Names Lock: repository-wide locked-name verification.

Acceptance requires completed/success runs and jobs on the exact new commit SHA, inspectable logs with zero exit codes, and the Stage03 artifact with matching SHA-256 and valid ZIP contents. A queued or in-progress run is not a PASS. No manual duplicate dispatch is authorized.

## 6. Exact-SHA acceptance record

Accepted code SHA: 43add99d816cc0a8b5feb17df3e76935957e5a90.

| Gate | Run / job | Result |
|---|---|---|
| Stage03 Native FPC 3.2.2 | 45683447859 / 139449698044 | SUCCESS; 128 cases; 1,541/1,541 assertions; 17 EXPECTED_RED; 111 MATCH; zero failures |
| Stage02 full regression | 45683447847 / 139449697992 | SUCCESS; WorkCounts 1,449/1,449; Context 1,730/1,730; Lifecycle 3,654/3,654; Discovery01 41/41 |
| Stage01 full regression | 45683447750 / 139449698038 | SUCCESS; all 30 exit markers zero; static UTF-8 7/7; dynamic UTF-8 12/12 |
| Canonical Names Lock | 45683447790 / 139449698294 | SUCCESS |

Verified artifacts:
- Stage03 artifact 15055372564; ZIP SHA-256 4be24f78f0c0fb84df848800485c652e9bdc39c774bb2496aeeaa3c96902e0a9. Embedded TSV SHA-256 f011be78e4e6fe8489f8ae4f1e5040c0c161e6376db8b4d7c38e15d86b5b0017.
- Stage02 artifact 15054094276; ZIP SHA-256 836173370a9758fe1d9bde8a4507ac7af0a260dedd2ba9cedd265760f1f95c42.
- Stage01 artifact 15053698862; ZIP SHA-256 2fd7a6b240401c15a31f1783d78df3f524c8c218d16fdeaa24ffce78cff942e3.

All three ZIP archives passed integrity checks. Their embedded logs identify the accepted code SHA exactly. The preliminary commit a2c8c8fa3fb0605fef07d3f9c945548d7becd02b failed Native compilation because the BigSave body was placed in the interface section; that attempt was superseded and none of its results were reused. The correction moved the body into the implementation section while preserving the BigRegularModPositive body byte-for-byte. All acceptance gates above belong only to 43add99d816cc0a8b5feb17df3e76935957e5a90.

Stage03 is accepted. Stage04 DISCOVERY02 (FOUNDATION_DAY_TAG) is the next planned stage and remains NOT_STARTED. No Stage04 implementation, main, merge, PR, or release is part of this patch.
