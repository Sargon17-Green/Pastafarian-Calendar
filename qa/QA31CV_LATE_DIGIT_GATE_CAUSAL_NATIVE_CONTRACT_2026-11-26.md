# QA31CV contract — later decimal iterations and causal gate intervention

**Purpose:** Extend the active-source QA31CP evidence beyond the first gate. This is a new Native corpus, not a rerun of QA31CP/QA31CT inputs.

## Pinned inputs

- Candidate: `src/work_counts.b98` Git blob `7418e1ec5fe88fe5c14b75710dea2d5607527f28`.
- Independent oracle helper: `qa/stage1_native_diverse_geometry.py` blob `bb626658309627704d0cdd2c162a1bdd16e1ad10`.
- Independent Befunge references: `reference/work_counts.b98` blob `f941efc793c9eee4accf5d03873f8ed029b16725`; `reference/save.b98` blob `7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44`.
- Runtime: PyFunge 0.5-rc2, SHA-256 `e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac`.

## Test contract

Each input has five decimal iterations. The Native hook records the real stack sum, weighted signed increment, dynamically written gate opcode, physical fetch, executed branch, arithmetic arm, and join stack at every iteration. It forces the opposite arm at a later iteration only (index 1 or 4), then checks that subsequent iterations continue normally.

| Case | Input fields (signC, magC, signT, magT) | Expected weighted increments | Forced iteration |
|---|---:|---:|---:|
| later_negative_tens | (0,12345,1,67890) | +5, -50, -500, -5000, -50000 | 1 |
| later_positive_tens | (1,12345,0,67890) | -5, +50, +500, +5000, +50000 | 1 |
| last_positive_ten_thousands | (0,54321,1,9876) | -5, -50, -500, -5000, +50000 | 4 |
| last_negative_ten_thousands | (1,54321,0,9876) | +5, +50, +500, +5000, -50000 | 4 |

## Oracle and expected outputs

- Healthy candidate output: all seven fields must equal the independent Native result from reference/work_counts plus the two independent reference/save runs.
- Counterfactual: for the selected weighted increment z, shift both signed input values by -z. The first five reference outputs must equal the forced-arm candidate output; the final two SAVE outputs must remain equal to the healthy case.
- Every run must record exactly five gate writes/fetches/joins; the forced run must record exactly one forced gate at its declared later index. The stack recurrence at every join must be S+z normally and S-z only at the forced iteration.
- Bounds: one IP, 300,000 maximum candidate steps per run, 220-second process watchdog, pinned PyFunge archive.

## Acceptance boundary

A passing job establishes late-iteration Native/differential evidence for this corpus. It does not by itself establish all-input termination, full Stage1 acceptance, spaghetti geometry acceptance, or authorization to merge/main.
