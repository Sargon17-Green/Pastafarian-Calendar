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
- **Final bounded hosted-CI diagnostic is configured** at commit `44bbee23387fdadbfcd158cccd504e3e652de0c8`: JavaScript heap 1.5 GiB, process virtual memory 5 GiB, hard 150s wall-time, low OS priority, capture GNU time maximum RSS; await actual result and inspect raw evidence. No local Windows permission is implied by this probe.

## Strict inference and next steps

1. Do not run JavaScript native on the current Windows system while the resource gate is blocked. The 2 GiB gate is a chosen conservative threshold, not a proved minimum.
2. Inspect hosted-CI bounded probe's actual Native result/RSS and decide whether original JS is feasible on a sufficiently idle machine or should remain `BLOCKED_MEMORY`.
3. Continue independently checking `B(c,Y)` whole-year boundaries and all original engine/wrapper classifications.
4. Only after both original converters return actual native output under **verified** local process/job/RAM/disk admission should the `v017` transport and `v018` raw-linkage gate be exercised on Windows.
5. No completed whole-year comparisons; no 10,000-year soak; `main` remains unchanged.
