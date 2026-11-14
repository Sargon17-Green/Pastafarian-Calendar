# Windows pilot admission v020 — confirmed bridge evidence, 14 November 2026

**Status:** `BLOCKED_RESOURCE_OR_SOURCE` (specific failing gate: RAM headroom).  
**Scope:** read-only resource and pinned-source checks; zero date calculations; zero converter children; no soak.  
**Run ID:** `20261114T214747Z_3d6e7732`.

## Ground truth

The original script `soak/runner/RUN_PASTAFARI_SOAK_WINDOWS_RESOURCE_PREFLIGHT_v020.py`
was transferred unchanged at Git blob SHA-1 `73203c64b4ac4872aeb1d9abd997318c65ade9a2` into the preexisting OTR Drive bridge. Verified source bytes before moving it into the watched folder. The bridge completed with exit code **2** and sent a result by Gmail.

The observed `PASTAFARI_SOAK_WINDOWS_ADMISSION_JSON` receipt reports:

| Gate | Observation | Result |
| --- | --- | --- |
| Windows operating system | Windows interpreter Python 3.13.3 | PASS |
| RAM headroom ≥ 2 GiB (pilot safety admission, **not** algorithm requirement) | 1,062,019,072 B free, 8,379,490,304 B total, 87% memory load | **BLOCKED** |
| Disk headroom ≥ 10 GiB | 38,923,628,544 B free (36.25 GiB) | PASS |
| Node.js discoverable | Yes; no Node process launched | PASS |
| Original Python+Türkçe snapshot | Locked exact source SHA-256 and Git blob SHA | PASS |
| Original JavaScript+Interlingue source | Locked exact source SHA-256 and Git blob SHA | PASS |
| Original JS language catalog | Locked exact source SHA-256 and Git blob SHA | PASS |
| Ephemeral CPU Job Object control capability | CPU rate 500, flags 5, read back on unassigned Job Object | PASS (capability only) |

The CPU probe **did not assign any worker** or measure throttling. Therefore it is **not** an execution resource-admission PASS for a converter. The handoff archive SHA-256 reported by the bridge is:
`707982f75e288ce1763b3ab7b821df47255bcaa668d7f16d51ef7d944d7d4855`.

**Machine-state side effects:** no converter calls, no child processes, no software installation, no Git main modifications. The temporary staging Google Doc used to transfer the exact text was deleted after checksum verification. No recurring checks or background services were created.

## GitHub Actions native micro-evidence

A separate hosted-CI native run evaluates one ordered input pair `F(c,t)` with `c=t=-15055671`, with pinned original source bytes and bounded resources. It is not a Windows certification.

- [Run 43643920160](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43643920160): original Python returned year 5000; cutlet 10, ordinal 503; month 20, ordinal 56, in 14.108s. JavaScript failed with a V8 heap OOM at a **256 MiB configured heap limit** (exit 134). No pair verdict.
- [Run 43644201078](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43644201078): source fetch connection reset before either native call; NOT an engine failure.
- [Run 43644278874](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43644278874): original Python again produced the same five fields (14.151s); JavaScript failed with V8 heap OOM at **768 MiB configured heap limit** (exit 134). No pair verdict.
- [Run 43644856799](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43644856799): the final bounded CI test at **1.5 GiB Node heap** still failed with a native V8 heap OOM (exit 134). GNU time measured **2,266,308 KiB (~2.16 GiB) peak RSS** before process abort. Python again returned the same five fields (9.917s). No pair result and no authorization to increase Windows resource usage. Do not automatically increase JavaScript's memory limit further.

## Strict inference and next steps

1. Do not run JavaScript native on the current Windows system while the resource gate is blocked. The 2 GiB gate is a chosen conservative threshold, not a proved minimum.
2. Original JS full-date reference remains `BLOCKED_MEMORY` at the bounded limits tested. Review memory complexity or use an explicitly non-original optimized alternative, without pretending it is the unchanged original for this soak.
3. Continue independently checking `B(c,Y)` whole-year boundaries and all original engine/wrapper classifications.
4. Only after both original converters return actual native output under **verified** local process/job/RAM/disk admission should the `v017` transport and `v018` raw-linkage gate be exercised on Windows.
5. No completed whole-year comparisons; no 10,000-year soak; `main` remains unchanged.

## Original native year5000 candidate concordance (not independently certified)

[CI 43645077409](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/43645077409) computed the year-5000 boundaries directly from both pinned original reference sources **without constructing month weaving**. Both returned:

- Calculation day: `-15055671`.
- Opening gate: index `-4`, day `-15057703`.
- Closing gate: index `4`, day `-15053459`.
- Candidate year's inclusive target interval: `[-15057702,-15053459]` — **4244 days**.
- Frozen candidate SHA-256: `b464d81b2d02cf6270092ee887f4e0f6d3668b0de67a64c4423e358984cfd276`.

The candidate is recorded in `soak/control/foundation_year5000_two_native_candidate_v021.json`, with explicit negative independent-oracle and soak-admission flags. `soak/tests/test_year_boundary_candidate_v021.py` checks arithmetic consistency and exactly re-derives the candidate receipt SHA. **Matching two source-derived boundaries does not yet establish a source-independent canonical proof or certify a whole-year transcript.**
