# Stage17 original interpreter failure diagnosis (2026-11-20)

PROJECT_ID: PC-BRANCH-FALSE-ARABIC

Historical Native workflow: https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/44811842615
Job: 136550139613 (completed/failure)
Run SHA: 5da77a462903d84f4f7ba692ecd36e400dbf4e04
Source pin: dfa6352c88768336e4ab3317d0c540f532e3c0b7
Original interpreter: eb3135565a8670cced3f6bbca4dbf7b014c45634

Downloaded original ZIP artifact 14668095856.
Artifact SHA256: bdb1bc25d6d09e54383d87f79e6c4c15888d58217313f2fd1657a00aabccfe58
37 ZIP entries; CRC self-check passes. Original interpreter compile exit 0, Unicode preflight passed, source pins matched.
Native positive: exit 1, zero success labels; stderr reports stack type mismatch on `s;0=&w;0=&[` in the Stage17 op34 implementation (line 741 of combined program).
Four invalid numeric rank programs: exits 1 with stdout `E_BALL_RANK`; they are diagnostic negative tests, not evidence that positive logic is valid.
Mutant exit 1 also at initial parser/type validation; cannot count it as mutation rejection.
Stage17 is NOT_ACCEPTED. Failed evidence does not constitute Stage17 PASS.

Remediation commit cc39bd7007d27f00643b800338432430167dbb40 replaces the invalid boolean conjunction with two nested guards, preserving the test fixture and all earlier operations. This is a new source SHA, so a new source-pinned Native execution is justified, but not yet proven. Full Native outputs, negative controls, independent oracle audit, and explicit acceptance still required. No main/merge.
