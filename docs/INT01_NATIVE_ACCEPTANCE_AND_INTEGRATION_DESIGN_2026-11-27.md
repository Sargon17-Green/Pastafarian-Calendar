# INT-01 bounded Native acceptance and next integration design

PROJECT_ID=PC-BRANCH-COBOL-SIMPLIFIED-CHINESE
TESTED_SHA=7b12fe744b47a7d50aa31a75fbb74121d944e9d8
Date: 2026-11-27

## Evidence
Dedicated natural push run 45954394918, job 140357408091, completed/success. Strict GnuCOBOL 3.2.0 compile with -Wstrict-typing -Wcall-params -Wlinkage -Wtruncate -Werror. WORK_COUNTS_CASES=00015; WORK_COUNTS_GATE=PASS. Exact test blob 0b3007411a9542f2d72e864395757a045fc836c2: each RUN-CASE increments only after four exact decimal outputs, direction, two unchanged inputs, occupied-output status 175, six FREE-A operations and HEAP-LIVE status 0 / length 0. Thus 15 measured zero-heap checks, not a separate printed heap counter. Occupied result content preservation after rejection is not directly compared in this harness. Artifact 15178266948, 687 bytes, SHA256 7c3a9d072ac447567a29022722d532b66bf4fce272a3d0240ff5e00567c36b4f independently matched downloaded bytes, ZIP CRC passed; one work-counts.log with exact project and SHA. Accept only INT-01's tested work-counts scope, not full calendar.

Canonical run 45954394882: connector first page 30 jobs, 29 successful, stage15 job 140357409056 failed before compiling due to apt HTTP 403 from packages.microsoft.com/ubuntu/24.04/prod/dists/noble/InRelease, exit 100; no stage15 log artifact. Not a reproduced arithmetic defect. Full canonical status and QA51-B repair gate not established by first-page data. Preserve historical Stage55 and QA51-B acceptance, do not rerun accepted stages merely to obtain green. No dispatch.

## Source gate
Targeted Library search located secondary audit pastafarian_converter_audit_v5_20261114.md reporting engineDay=JDN-1721425 and foundation -15055671; not authoritative Appendix A. The cited Wikisource page returned 404. Do not implement civil epoch/inverse or normative constants using the secondary audit alone. Acquire a version-pinned authoritative text and record its hash and exact rule citations before deriving fixtures or production formulae.

## Proposed independent production interfaces (planning, not implementation)
All operations accept explicit calculation-day and target-day context; no clock defaults. Use existing BigInt owner ABI, immutable inputs, canonical-empty distinct outputs, explicit nonzero status on errors, zero outstanding allocations after caller release. No linking normative test oracle. Freeze numerical semantics from pinned primary specification before writing each component.
- Gate/year: input the four INT-01 counts and direction; output year and within-year rank, interval start and length. Check rank in [1,length], exact start/end and adjacent boundary, monotonic boundary search only if proved from rules. Use bracket doubling and binary search if monotonicity holds, with explicit step bound derived from input bit length; otherwise use a proven exact algorithm, not unbounded scan.
- Sauce/selection: input year context and normative integer selector; output canonical catalog indices and rank, reject outside valid index/rank domains. Test every boundary, tie and zero/one cases from the primary text.
- Family count/unrank: input rule-defined family parameters and rank; output exact selected family member. Prove count and rank/unrank inverse; compare exhaustive enumeration on small domains and independent large integer combinatorics, test rank 1, count, 0, count+1. Never enumerate an unbounded family in production.
- Weaving: input year layout, cutlet/month families and target rank; output cutlet/day and month/day. Independent small explicit sequence enumeration, coverage and bijection checks if the specification implies them; verify first/last and interleaving transitions. Avoid assuming months are contiguous.
- Civil forward/inverse: validate Gregorian date and epoch; keep calculation-day fixed in round trips; inverse must distinguish no match, unique match, and ambiguity per authoritative semantics. Never silently choose a candidate. Exercise signed years, leap/century cases, exact epoch anchors, 2026 sweep and extended-year deterministic differential testing after source lock.
- Proposed QA: per module compare small exhaustive reference and boundary fixtures derived from text independently of implementation; include occupied-output cases, input immutability, heap zero, timeout and deterministic seed. Record exact commit/compile/job/log/artifact. No acceptance for planning alone.

No Stage56, main, merge, release or reopening the three excluded fault paths. Docs-only child is not a new Native test; skip CI to avoid duplicating accepted work-counts execution.
