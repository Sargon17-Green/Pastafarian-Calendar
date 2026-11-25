# Stage 04 — DISCOVERY 02: FOUNDATION_DAY_TAG (preflight audit)

PROJECT_ID: PC-BRANCH-OBJECT-PASCAL-PORTUGUESE  
Branch: Object-Pascal+Português  
Audited branch HEAD before this document: 8d05c6c920ad3e278b0fe3e3d306f659319453b8  
Preflight status: **NO EXPECTED-RED FOUND; STAGE 04 NOT ACCEPTED**  
Production source changes: none. Stage 05: not started.

## 1. Frozen plan and normative source

The machine-readable 55-stage plan is pinned at commit
`0c2bad7393f4d66b77f884520f8ab6f5025feedd`. Its Stage 04 row is:

```text
4,DISCOVERY,02_FOUNDATION_DAY_TAG,EXPECTED_RED_AND_LIVE_LEGACY_PATH,NOT_STARTED
```

The normative source is `README.md` at
`56bc4173aae4975ded019ef5ab5a36249f1424df`, Sections B-C:

- Foundation Day absolute ordinal: `F = -15,055,671`.
- Foundation Day has tag 1.
- For `d > F`, `N(d) = 2(d-F)+1`.
- For `d < F`, `N(d) = 2(F-d)`.

The Foundation Day's two published date representations also agree:
Gregorian 22 December 41,222 BCE and Julian 28 October 41,221 BCE.
The independent JDN check in the oracle below gives the same JDN
`-13,334,246`, hence absolute ordinal `-15,055,671` when Gregorian
0001-01-01 is ordinal 1.

## 2. Existing live production path

The only production implementation of the Foundation Day tag in the current
branch tree is:

- `src/Stage02WorkCounts.pas::CountForDay`
- Current source blob at audited HEAD: `88da645965a0898a5217718582dc829e04afff2c`

Its implementation is:

```pascal
Foundation := BigFromInt64(FoundationDay);
if BigCompare(Day, Foundation) < 0 then
begin
  Offset := BigSubtract(Foundation, Day);
  Result := BigMultiplyUInt32(Offset, 2);
end
else
begin
  Offset := BigSubtract(Day, Foundation);
  Result := BigAdd(BigMultiplyUInt32(Offset, 2), BigOne);
end;
```

This is algebraically identical to the normative formula, including equality:
when `Day = F`, the second branch computes `2*0+1 = 1`.
The `TBigInt` operations are arbitrary precision; the day argument is not
restricted to Int64.

The test-only `NormativeOracle.DayCount` at blob
`cccddafdf05bc2eb409b060e6f873331b9e24d49` expresses the same rule with an
explicit equality branch. The independent Python oracle
`docs/stage02_workcounts_oracle.py` (blob
`27ff87de104eae893a94ad0f6a46aa8e76e83872`) uses Python arbitrary-precision
integers and the normative constant from the README.

## 3. Existing Native evidence relevant to this path

The Stage 03 exact-code-SHA acceptance record confirms that the full Stage 02
regression ran on code SHA
`43add99d816cc0a8b5feb17df3e76935957e5a90`:

- Stage 02 run `45683447847`, job `139449697992`, completed/success.
- WorkCounts: 1,449/1,449.
- Context integration: 1,730/1,730.
- Lifecycle: 3,654/3,654.
- Discovery01: 41/41.
- Stage 01 run `45683447750`, job `139449698038`, completed/success.
- Canonical Names Lock run `45683447790`, job `139449698294`, completed/success.

These results belong to the exact tested code SHA above; the current branch
HEAD `8d05c6c920ad3e278b0fe3e3d306f659319453b8` is a docs-only descendant.
No accepted run is being repeated.

The 96 WorkCounts vectors include the Foundation Day in the equal-day group,
nearby values in the adjacent group, signed integer boundaries, and very large
signed values. The existing Python oracle additionally self-checks
`N(F-k)=2k` and `N(F+k)=2k+1` for `1 <= k <= 512`. The 1,024 boundary
identities in that oracle are oracle-side checks; they must not be represented
as 1,024 Pascal Native cases.

## 4. Measurable Stage 04 preflight contract

The bounded contract used for this audit is:

- **Input:** any signed arbitrary-precision absolute day ordinal `d`.
- **Output:** the positive Foundation Day tag `N(d)`.
- **Independent oracle:** Python integers; `delta=d-F`; return `-2*delta`
  when `delta<0`, otherwise `2*delta+1`.
- **Required boundaries:** `F-512 .. F+512` (1,025 days), plus signed
  Int64 edges, zero, and powers of two around 63, 64, 127, 128, 255, 256,
  512, 1,024, 2,048 and 4,096 bits.
- **Properties:** `N(d)>=1`; even tags iff `d<F`; odd tags iff `d>=F`;
  inverse round-trip; no collisions on the probe set; `N(F)=1`;
  `N(F-k)=2k`; `N(F+k)=2k+1`.
- **Anchor check:** the normative Gregorian and Julian Foundation dates map
  to the same JDN and to ordinal `F`.

The independent oracle was committed at
`834eb56a96db1c6b0a67f1d7b3f07bf4c345c048`:
`docs/stage04_foundation_day_tag_oracle.py`, blob
`80f981204d8334aec0b15a36e52174b4890fee45`.

Its Python-int preflight completed with:

- 1,072 unique probes (1,025 consecutive boundary days + 47 extra extremes).
- 1,024 explicit before/after boundary identities.
- 4,096 inverse-tag round trips.
- Tag injectivity on all 1,072 probes.
- Gregorian/Julian JDN anchor equality.
- Maximum tag width: 1,234 decimal digits.
- Deterministic TSV SHA-256:
  `74dc3e3d4ea07eeebed2647c798c7a3e1cbf91877e73a65351370a58c7e7ecab`.

This is an independent Python oracle preflight only. It did **not** compile or
execute Pascal, and is **not** Native, differential, or Stage 04 acceptance.

## 5. Finding and gate decision

No mismatch was found between the normative formula and the only live
production path `CountForDay`. The source expression is algebraically
equivalent, the exact-SHA Stage 02 Native regression already exercises it,
and the independent preflight found no mathematical inconsistency.

Therefore:

- No `EXPECTED_RED` is evidenced.
- No defect, failure, or expected-red case is being invented.
- No production patch is justified.
- Stage 04 remains **NOT ACCEPTED** under the common plan's
  `EXPECTED_RED_AND_LIVE_LEGACY_PATH` gate.
- Stage 05 PATCH 02 remains unstarted.
- `DEVELOPMENT_STAGE.md` and the common 55-stage plan were not changed.

## 6. Required decision / next step

The current source tree contains no second production Foundation-Day-tag path
to test. To proceed without changing policy, the missing input is either:

1. the distinct legacy path or known semantic discrepancy intended for
   Stage 04; or
2. explicit authorization to amend the common Stage 04/05 acceptance plan to
   account for the fact that the existing production path already matches the
   normative rule.

Until that is resolved, do not claim Stage 04 PASS, do not create an artificial
RED, and do not start Stage 05.


## 7. Exact-SHA Actions, logs and artifact readback

The underlying GitHub run/job metadata and downloaded ZIP bytes were
independently checked; no run was repeated.

All four records below identify the same tested code SHA
`43add99d816cc0a8b5feb17df3e76935957e5a90`, branch
`Object-Pascal+Português`, attempt 1:

| Gate | Run / job | Run + job |
|---|---|---|
| Stage03 Native FPC | 45683447859 / 139449698044 | completed / success |
| Stage02 regression | 45683447847 / 139449697992 | completed / success |
| Stage01 regression | 45683447750 / 139449698038 | completed / success |
| Canonical Names Lock | 45683447790 / 139449698294 | completed / success |

Downloaded artifact checks:

- Stage03 artifact 15055372564: 15,626-byte ZIP; SHA-256
  `4be24f78f0c0fb84df848800485c652e9bdc39c774bb2496aeeaa3c96902e0a9`;
  CRC test passed. Embedded log SHA-256
  `2224feddcf850a66b2710f4d05f42e2d3a10448e152dd63eb19867c05ecdc02d`,
  strict UTF-8. It records FPC 3.2.2, 128 cases, 17 EXPECTED_RED,
  111 MATCH, 1,541 checks passed, zero failures and `STAGE03_EXIT=0`.
  Embedded TSV SHA-256 is
  `f011be78e4e6fe8489f8ae4f1e5040c0c161e6376db8b4d7c38e15d86b5b0017`.
- Stage02 artifact 15054094276: 4,509-byte ZIP; SHA-256
  `836173370a9758fe1d9bde8a4507ac7af0a260dedd2ba9cedd265760f1f95c42`;
  CRC test passed. Embedded log SHA-256
  `7c7e864792790ba7b7e6e4776288c485864af4d9089c29081dea76b6280152a3`,
  strict UTF-8. It records FPC 3.2.2, exact source SHA, WorkCounts
  1,449/1,449, Context 1,730/1,730, Lifecycle 3,654/3,654,
  Discovery01 41/41 and `STAGE02_EXIT=0`. The 96 WorkCounts rows include
  inputs at `F-1`, `F`, and `F+1`; the artifact TSV SHA-256 is
  `1a25f13aacd70d3cf23458d331c7a9148c5d749994099c2c9c9c4849ce674d12`.
- Stage01 artifact 15053698862: 4,050-byte ZIP; SHA-256
  `2fd7a6b240401c15a31f1783d78df3f524c8c218d16fdeaa24ffce78cff942e3`;
  CRC test passed. Embedded log SHA-256
  `3bd5dfc059b00345ddc630079153886321f310ae22e2d7cae43a891c2242062b`,
  strict UTF-8; 30/30 suite exit markers are zero.

The artifact sizes and hashes above were computed from the downloaded bytes,
not copied from the report. The Stage02 Native evidence directly exercises the
live `CountForDay` path through `ComputeWorkCounts`; it does not supply a
Stage04 EXPECTED_RED. These are historical exact-SHA acceptance records, not
new Stage04 tests and not a reason to rerun them.
