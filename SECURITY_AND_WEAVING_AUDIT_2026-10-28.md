# Native QA security and independent month-weaving audit
Date: 2026-10-28

This document records the current evidence. It is human-readable documentation,
not an executable, a substitute for CAL, or an authorization to disable security
software. The code in `source/` remains Plain English Programming.

## Native execution status

- The last successfully compiled Native QA source was v137. Its Windows run did
  not pass all 99 groups: the 47-month weaving test produced `1260` rather than
  the independently verified 73-digit reference and the process timed out.
- The next attempt, v138, did not execute CAL. Microsoft Defender on
  `ELIEZER-GREEN-2` detected `cal-4018.exe` as
  `Trojan:Win32/Zpevdo.B` (threat ID `2147729093`).
  Defender event IDs 1116 and 1117, on 2026-10-23, confirm successful
  quarantine with result `0x00000000`.
- The compiler was obtained from the historical `Folds/english` repository,
  pinned to commit `5412ac7dc4d09cb1cca2f4307148ef39d15958aa`.
  Provenance and exact bytes do not establish safety. Its source code being
  present in that repository does not establish a reproducible trusted build.
- DO NOT execute, re-download, restore from quarantine, or whitelist the
  compiler while the detection remains unresolved. This branch has no new
  native PASS since the security event. The 99-group, full and soak acceptance
  gates remain open. The `main` branch must not be changed.

## Proven separate logic defect: invalid month completion order

A suffix may start its months in correct ordinal order yet contain a later
month already finished while an earlier month still has days remaining.
For two months with four days each, remaining counts `(2, 0)` are impossible
under the mandatory last-occurrence order. Such a state must have zero legal
completions; the direct last-occurrence product used to return `1`.

This defect is independent of the 47-month Native failure. It does not
explain why the earlier run returned `1260`; there is currently no reliable
Native witness identifying that cause.

The branch now checks that both the set of started months and the set of
finished months are ordinal prefixes, before either closed-form shortcut
can produce a value. It adds a regression case for the impossible `(2, 0)`
state to the existing shortcut QA group, leaving the count of groups at 99.
The definitions of the calendar and existing reference values are unchanged.
New and modified CAL source has NOT been compiled with a verified safe tool.

## External, safe, independent verification

An external Python standard-library audit was run separately from this
language branch. This is NOT source code of the Plain English implementation
and must not be added to this branch. No third-party executable was launched.

The audit used a shortcut-free legal-next-month recurrence as oracle, checked
every remaining-count vector for 2, 3, and 4 four-day months (25 + 125 + 625 =
775 vectors), and compared the repaired prefix-aware shortcut against it.

| Months | Old direct shortcut candidates | Old mismatches | Repaired-model mismatches |
| --- | ---: | ---: | ---: |
| 2 | 20 | 3 | 0 |
| 3 | 80 | 27 | 0 |
| 4 | 320 | 159 | 0 |

All nine specific fixtures passed, including `(2, 0) -> 0`. Two different
exact integer expressions for the 47-month all-started case agreed:
`product(j=1..47) C(2j-1,1) = 1*3*...*93 = 93!!` =
`2987435000850314871976096554696085799164511452611632783323554397412109375`.

The external verification script and machine-readable results are stored in
the ChatGPT project Library, not committed to this repository. The JSON
evidence SHA-256 is
`75911dfa1b492cb12c92ba0f2e978794682e91e240cf79df1060999dc238e4b4`.

## Resume conditions

1. Obtain a trusted, separately validated compiler path or professionally
   resolved false-positive finding. Do not weaken Windows security.
2. Recompile the current branch with that safe tool. Test the new helper
   syntax and forbidden-finish regression first.
3. Continue the original v137 47-month mismatch investigation, using the v138
   detailed witness instrumentation; do not treat the external audit as
   Native verification.
4. Only after all 99 quick groups pass should full and soak testing resume,
   with bounded execution and preservation of failures.

## Follow-up: bounded 47-month fixture preflight and extended audit

A further source-only change has been made to `source/the weaving shortcut checks`.
Immediately before the potentially expensive 47-month counting call, the
existing QA group now inspects the actual linked records and refuses to enter
the count unless all four fixture properties hold: exactly 47 records, two
remaining days in every record, 47 months already started, and no month
finished. Failure generates a distinct test-report message; no reference
count, calendar rule, or resource ceiling was relaxed. This may prevent a
runaway recursive fallback when a faulty setup is responsible, but is not a
confirmed fix for the previously observed `1260` result. It has **not** been
compiled or run with CAL following the quarantined-compiler event.

A new safe, independent Python arithmetic audit extended exhaustive tests to
**19,525** remainder vectors across 2–6 synthetic four-day months. The
prefix-checked direct/short-cut models were applicable in **19,269** cases;
all matched an independently cached legal-next-occurrence recurrence.
A further five independent-model tests checked the new 47-record preflight,
including wrong list length, wrong remaining count, unstarted and finished
months; all passed. The 73-digit `93!!` oracle was reverified by two exact
formulas. These results validate the *mathematical model only* and do not
prove the CAL parser/compiler or runtime behavior.

External audit files, kept outside the Plain English Programming branch:
`PEP_WEAVING_SAFE_STATIC_AUDIT_v140.py` and
`PEP_WEAVING_SAFE_STATIC_AUDIT_v140.json`. JSON evidence SHA-256:
`2e26e1c1c3202248c21304b3a3b3d6779607afe5b156d0cd50ed92287eaf897a`.

Work remains SECURITY_BLOCKED_CONFIRMED. Do not resume Native execution using
the quarantined compiler or bypass Defender. After obtaining a separately
validated compiler, verify syntax of the added preflight, run the original 99
QA groups, and investigate the first real observed mismatch before full/soak.
