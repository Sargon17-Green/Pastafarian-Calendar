# Stage 1 — first Icarus Verilog job log review

As of 2026-10-22.

## Verified GitHub Actions run results

| Run | Trigger | Source commit | Outcome | Independently visible PASS before failure |
|---|---|---|---|---|
| [39763869338](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39763869338) | isolated QA push | `81e39313cb30aac45c773cbcf3be7a2e1c290351` | FAILURE | bootstrap primitive; reset recovery |
| [39763937760](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/39763937760) | PR to isolated QA (not main) | `65a72632ec2e1b44576ca75b4775dc01a2725a86` | FAILURE | bootstrap primitive; **4103** arithmetic properties; reset recovery |

Icarus Verilog **12.0-2build2** was successfully installed on
GitHub-hosted ubuntu-latest in the first run. These claims come from
GitHub's actual job logs, not from scratch source inspection.

### Root cause

First failure:
```text
tests/tb_sauce_foundation.sv:16: syntax error
tests/tb_sauce_foundation.sv:1: error: Syntax error in variable list.
...
Process completed with exit code 12.
```

The offending identifier was `dist`, a reserved SV token used in
distribution constraints. All subsequent error locations are a cascade
from the same declaration and references. Both baseline runs stopped
before any Foundation sauce assertions could execute.

### Remediation and regression

- `a450565858acc58d91588ac0800cfe03815fd811`: rename that
  variable to `distance_count` in both independent SV sauce testbenches.
- `2bc45cb3b8db0fdbd2d5c4889638b6d5e36aa33e`: improve shell/AWK
  preflight to examine module-level `integer` and `logic` declarations
  and prohibit reserved words.
- `a1e27bd3f1ee700c76664f79afe116993b7eeed4`: add a negative
  test fixture for the exact old `dist` mistake.
- `tests/tb_stage1_backpressure.sv`: 4096 cycles, not yet executed.

### Remaining gates

No simulator PASS has yet been observed for the Foundation sauce,
raw-sum mutant, negative/positive gates, Year 5000 selection, rejection
equivalence, or 4096-cycle scoreboard. The 64-name native-language
catalog is still **0/64 approved**, and the full five-field calendar
oracle is not implemented.

Current HEAD must be re-executed on an authorized CI runner; its
existence in a queue does not count as success. Stage 1 and all 55
contract stages remain incomplete.
