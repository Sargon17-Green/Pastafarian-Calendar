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

## Additional source-only development: isolate the 47-month shortcut

The 47-month case now has three separate checkpoints **within the existing
quick QA group**, leaving the group count at 99:

1. Check the linked fixture: exactly 47 month records, each with two days
   remaining, all 47 already started, and none finished.
2. Invoke `Count ordered last weaving suffix completions` directly. Require
   `available = 1` and exact `93!!`; if not, report the direct-count
   failure with actual decimal value and fixture metadata, rather than
   entering the expensive recursive fallback.
3. Only after the direct count passes, invoke `Count weaving completions`
   through the general entrypoint. A mismatch at this point now separates
   entrypoint/call-state problems from a direct binomial-product problem.

**None of these checkpoints has yet been run in CAL.** They do not establish
the cause of the old `1260` result, and they do not constitute a Native QA
pass. In particular, an assembly listing proving the presence of a call is
not runtime evidence that all 47 records were allocated or that a parameter
was populated. Continue to preserve the Defender quarantine and the
`SECURITY_BLOCKED_CONFIRMED` acceptance state.

The final source-only commit for this probe is
`26f6d5be51df657af219be33312047590911e809`.

## 2026-10-29: CAL-4700 staged on the user's Windows host; security review pending

The user's `CAL4700_INSTALL_RESULT(2).txt` records that installer v5
successfully placed `cal-4700.exe` at:
`%LOCALAPPDATA%\\Programs\\PlainEnglishCAL4700\\CAL4700_2d44defd\\cal-4700.exe`.
The source archive was pinned to `elenderg/PAL-1000` commit
`2d44defdedf24519bba754114ee66e6d1defff1e`, with ZIP SHA-256
`A1E7B9D96373562AEE7E1CBC8EBB5FCC237C46EB6D621FCF69D532FB8DE14165`.
The install report asserts that the binary was **not run**, no Defender
exceptions were added, and execution policy was unchanged. A completed
Defender scan does **not** prove executable safety.

A separate single-file, read-only Windows audit was prepared outside the
repository in the ChatGPT Library folder `/Pending_User_Execution/`:
`CAL4700_SECURITY_AUDIT_v1.cmd`. It performs **no compiler execution and
no downloads**; it records the installed executable's SHA-256, PE header
and expected size, compares the SHA-256 with the installer's evidence file,
checks Authenticode status and Defender health, and reports matching Defender
detections/events. It explicitly marks the compiler *not approved*, even if
the local file-integrity checks agree. The package has static checks only
and has not itself been executed on Windows.

**Current acceptance:** CAL-4700 INSTALLED / NOT EXECUTED / NOT
INDEPENDENTLY SECURITY APPROVED. CAL-4018 remains quarantined; the
47-month result of 1260 remains unresolved; 99 Native QA groups, full
and soak are **not verified**. Next gather the read-only audit report,
review any security signals, and only if independently cleared consider
an isolated, minimal compile smoke test. No bypass of security protection
and no premature Native PASS.

## 2026-10-30: source-vs-installed differential needed before CAL execution

Read-only audit evidence from `ELIEZER-GREEN-2` reported:

- Installed CAL-4700 executable: 831,515 bytes, SHA-256
  `D5D15179E7A07D7A8194C72B60473F28C1610CFAAEB6CC37BE9FAF3D43288614`.
- ZIP central manifest: executable **831,488 bytes**, CRC32 `065DDF49`.
- Executable is unsigned (Authenticode `NotSigned`), PE machine x86; the
  local Defender scan found no matching detections but cannot establish safety.
- Local installer evidence hash equals installed hash; this confirms only
  installer-to-current-file stability, not correspondence to the ZIP manifest.
- Original pinned ZIP is 936,482 bytes, SHA-256
  `A1E7B9D96373562AEE7E1CBC8EBB5FCC237C46EB6D621FCF69D532FB8DE14165`.
  Inspection of its raw ZIP directory reveals a 16-byte central-directory
  offset mismatch and a 6-byte discrepancy between the first executable's
  declared compressed size and the physical span to the next local header.

The metadata inconsistency alone is **not** proof of malware and does not
identify which version of the executable is correct. A separate read-only
Windows diagnostic `CAL4700_SOURCE_INTEGRITY_AUDIT_v2.cmd` has been placed
in the ChatGPT Library's `/Pending_User_Execution/` folder. It downloads
only the pinned original ZIP to a temporary folder, verifies its SHA-256,
tries direct raw DEFLATE extraction of the first entry, computes its CRC32,
and compares the independently inflated bytes with the installed executable.
It does not execute any EXE, install files, or change Defender settings.
This new diagnostic is **not yet executed on Windows**; its source was
reviewed statically and the archive-handling approach was exercised against
an independently generated benign test ZIP.

**Gate unchanged:** do not run CAL-4700 or CAL-4018. No Native QA PASS has
been established and no fix for the historical 47-month `1260` result is
claimed. Determine whether the ZIP itself is damaged or the installer
altered the program before considering a new trusted source or an isolated
compilation test.

## 2026-10-30: independent source payload differential -- confirmed

The user's original-host, read-only audit report
`CAL4700_SOURCE_INTEGRITY_RESULT.txt` records a successful download
of the SHA-256-pinned 936,482-byte GitHub archive, followed by independent
raw-DEFLATE extraction of the compiler's first ZIP member. Results:

| Datum | Value |
| --- | --- |
| ZIP manifest uncompressed executable size | 831,488 bytes |
| ZIP manifest CRC32 | `065DDF49` |
| Independently inflated executable size | 831,515 bytes |
| Independently inflated executable CRC32 | `7515BE6E` |
| Independently inflated executable SHA-256 | `D5D15179E7A07D7A8194C72B60473F28C1610CFAAEB6CC37BE9FAF3D43288614` |
| Installed executable SHA-256 | same, byte-identical |
| ZIP directory offset discrepancy | -16 bytes |
| EXE compressed physical span / declared length | 253,669 / 253,675 bytes |
| Native execution | NONE |
| QA acceptance | BLOCKED |

Interpretation: the v5 installer preserved the independently inflated
executable, but the compressed archive's actual decoded payload is
inconsistent with its recorded expected size and CRC. Merely repairing ZIP
directory metadata was insufficient. This confirms a **source archive
integrity mismatch**, not that the downloaded executable is malicious.
The unsigned CAL-4700 executable remains **not approved for execution**.

A check for other available provenance (original Osmosian distribution,
GitHub mirrors, authorized Folds repos) did **not** produce an independently
verifiable clean CAL-4700 executable in this review. The original
`https://www.osmosian.com/cal-4700.zip` is historically referenced but
could not be fetched and verified from the current environment. Alternatives
such as CAL-3040 and the Folds dynamic fork have not been independently
security approved either. No source binary should be silently swapped in.

**Next real gate:** obtain an independently authentic, integrity-consistent
compiler release or a reproducible, scrutinized build from source, then
conduct an isolated minimal compile before full 99-group QA. Do not execute
the installed CAL-4700, run the quarantined CAL-4018, bypass Defender, or
claim the 47-month issue or Native QA resolved.
