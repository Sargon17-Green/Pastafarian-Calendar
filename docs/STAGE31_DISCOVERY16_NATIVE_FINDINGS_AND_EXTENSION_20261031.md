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
