# Stage31 / Discovery16: observed First/Step evidence and bounded extension

Branch: PowerShell+Tagalog. Research-only. Tested SHA: 0bdac4b1d3288174e3f425fdb1e6a36fbd137f39
Completed run: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196570827
Windows PowerShell 5.1 research job 124523820440: success; native predecessor job 124523820228: success; verify job 124523820562: success.
Permanent artifact: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41196570827/artifacts/13041567173
Artifact SHA256 (job log): 6a7f50692ae096c7526f6a36d8ab72dc81288806ace82ff76c0e71e2e21e619f.

## Native finite observations
Twenty-five distinct enumerated calculation/target ordinal pairs, two seals each: 50 unique rows, independent NormativeScroll oracle agreement for First and Step in every row, range 1..M and sign {-1,+1} in every row, exactly 58 memory writes and one Patch12 invocation per row.
Four metadata assertions plus 300 row assertions plus five aggregate assertions = 309 passing assertions, zero failures.
Positive Step: 27; negative Step: 23. Distinct First: 50; distinct (First,Step): 50; repeated joint states: 0.
Min First: 829113323670314070510698460959537326; max First: 163998264249854863749362485830862137058.

| Calculation offset | Seal | Rows | Step +1 | Step -1 |
| --- | ---: | ---: | ---: | ---: |
| 0 | 1 | 22 | 11 | 11 |
| 0 | 2 | 22 | 11 | 11 |
| 1 | 1 | 3 | 3 | 0 |
| 1 | 2 | 3 | 2 | 1 |
| Total | both | 50 | 27 | 23 |

These are deliberately selected ordinal days, not random dates; no uniformity, independence, date entropy, or Stage31 seal is established. The Stage26 historical expected-red remains untouched.

## New bounded extension (research-only)
Use the same normative oracle and the same Stage30-preserving metadata checks. Foundation day F=-15055671. Calculation day = F + C, where C belongs to {-366,-1,2,366,36525,36526}. Target day = calculation day + D, where D belongs to {-36525,-366,-1,0,1,36525}. Both seals 1 and 2 for each pair: 6*6*2=72 unique, non-overlapping observations (relative to the old calculation shifts 0,1). The integers 36525 and 366 are day distances, not asserted calendar-year boundaries.

For each row check both oracle coordinates, First 1..M, Step in {-1,+1}, 58 writes, one Patch12 call (6 assertions); four preflight metadata assertions; five aggregate bounds/conservation assertions. Expected 441 assertions, 72 row records, zero failures. Record sign frequencies, distinct First/joint counts and repeats without prescribing the outcomes. Runtime: Windows PowerShell 5.1, 20-minute timeout, SHA-pinned checkout and retained artifact. No production code or stage metadata edits.

NEXT: inspect the completed log on the new SHA and the extension job; if red, repair the actual observed failure; if green, assess further date/boundary coverage and seal prerequisites. Do not mark Stage31 complete merely because finite samples pass. Note: STAGE30_SEAL_COMMIT_NATIVE_RECHECK=PENDING is historical/stale after completed Stage30 exact-seal run 41193007152; defer a metadata gate update until compatibility evidence is reviewed. No main merge.

## Stage31 extension completed and boundary characterization (2026-10-31)

Exact branch SHA: `dd4fc94347872f82b4a9378cab5038966a0e7b2d`. [Run 41199877830](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199877830) completed/success. Native Windows PowerShell 5.1 extension job 124533403392 succeeded with **72 rows, 441/441 assertions, zero failures**: positive Step=28, negative Step=44, distinct First=72, distinct (First,Step)=72, repeated joint=0. Independent oracle First and Step matched on all rows; 58 memory writes and one Patch12 call per row.
[Extension artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199877830/artifacts/13041999921); SHA256 `d9969e9f9a3f932ead6a286904dc11a8c8cb868569df14ee48dafae186409a7c`.

Original Stage31 probe was rerun on the same SHA: research job 124533403520 succeeded with 50 rows and 309/309 assertions; positive=27, negative=23, distinct First=50, distinct joint=50, repeats=0.
[Ordinal artifact](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41199877830/artifacts/13042112726); SHA256 `416dd6ddaf6a966294c339b7a90eb7fabd95e19a7c11efc546357de7789ccbdf`.
Predecessor Windows job 124533403607 and verify job 124533403667 succeeded, including Stage30 96/96 evidence-only and Stage23 twice idempotent (same source SHA256 `C98CD8E4CEC1CD7D9CE09DB6C43E4F55CED89F7D9C316A3ED2B45C12545E0A51`).

Together 122 deliberately selected, not probabilistically random rows; do **not** infer independence, uniformity, or all-date correctness. The offsets 365, 366 and 36525 are not certified year boundaries. `oracle/NormativeCalendar.ps1` instead chooses variable-length Pastafarian years by enumerating 41..962-day gate gaps and a candidate year 252..5778 days long. This motivates a further **12-row oracle-derived genuine year-5000 boundary probe**, formally specified in [Stage31 boundary contract](STAGE31_DISCOVERY16_NORMATIVE_YEAR_BOUNDARY_CONTRACT_20261031.md). Its Native result is pending on the next commit, not PASS.

Stage31 remains an inquiry. The stale `STAGE30_SEAL_COMMIT_NATIVE_RECHECK=PENDING` marker in DEVELOPMENT_STAGE.md has documented completed/success exact-seal evidence [run 41193007152](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41193007152); this research commit deliberately does not edit stage metadata or its regression gates.
