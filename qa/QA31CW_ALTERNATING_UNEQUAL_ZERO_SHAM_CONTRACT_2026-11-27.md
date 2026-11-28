# QA31CW — alternating signed increments, unequal decimal lengths and zero sham

Project PC-BRANCH-BEFUNGE98-KYRGYZ, 2026-11-27. QA-only contract and independently calculated arithmetic oracle; no production modification.

## Prerequisite acceptance
QA31CU completed/success run 45913989517 job 140228724783 on 244dce10aedc9a939508948329a35a8452d4e88d, artifact 15161104615, ZIP SHA256 6b69a5f7d7fcf1f4a010f9bc2fb7aa481e6212c0f0df2803309f2ee1e1f75e26; all 25 CRCs verified independently. Composition JSON SHA256 393d0fba4068519d787104691d908ee38a1160b2af90a7e5abccbfd4690bf8fc. Independently matched raw paginated metadata to merged and aliased files (CP 1/1, CT 1/1, regression 87 jobs/69 artifacts; ID, SHA, branch, attempt and successful completion). Compared the two original source blobs: 61 changed glyphs, rows 1046/1047/1048/1050, x=959..1022; active blob 7418e1ec5fe88fe5c14b75710dea2d5607527f28, baseline 560d6aa5807a7f766213a33835cce85eab0fa40c. CP two forced-output deltas independently checked: [-2z,-2z,0,-4z,0,0,0]. Historical CP/CT ZIP validations retained from preceding evidence; not re-run. CV Native scoped acceptance retained. CU document's historical 30-job count was an incomplete first page; 87 is authoritative. Stage1 remains NOT_ACCEPTED.

## New bounded contract
Use active blob above, PyFunge archive SHA256 e72d8beec82082134a752c9e23f131092bf1fe9e0f39d2c20c9de25bfbcfd4ac; independent Befunge references work_counts f941efc793c9eee4accf5d03873f8ed029b16725 and save 7b5e79aa6e2bfb636717cb018a3db6a13fb2bb44. Use QA31CV physical hook instrumentation only within this branch, not its corpus. Four new canonical inputs (signC,magC,signT,magT), five iterations per run:

| Input | Expected signed weighted increments (little-endian) | Sum | Separate single-intervention indices |
|---|---|---:|---|
| 0,90709,1,68020 | 9,-20,700,-8000,30000 | 22689 | 1,3 |
| 1,90709,0,68020 | -9,20,-700,8000,-30000 | -22689 | 1,3 |
| 0,10502,1,9807 | -5,0,-300,-9000,10000 | 695 | 0,1,4 |
| 1,10502,0,9807 | 5,0,300,9000,-10000 | -695 | 0,1,4 |

Calculated independently using integer divmod and checked against signed whole-value addition for all four cases. For signed values C,T and selected increment z, the alternate oracle input is (C-z,T-z), canonically re-encoded (no negative zero); reference first five fields plus healthy final two SAVE outputs. At zero z force opposite opcode as sham; require changed physical arm and identical seven output fields. For nonzero z require deltas [-2z,-2z,0,-4z,0,0,0]. At every gate require physical write before fetch, expected signed arm, correct join recurrence S_next=S+z except intervention S_next=S-z, and subsequent iterations normal. Record all gate coordinates, write/fetch/join ticks, stack operands and full outputs. Compare candidate and independently executed references, not copied expected output.

Independent arithmetic control values (C',T'; sum delta):
- alternating_C i1 (90729,-68000;40), i3 (98709,-60020;16000)
- alternating_T i1 (-90729,68000;-40), i3 (-98709,60020;-16000)
- unequal_zero_C i0 (10507,-9802;10), i1 (10502,-9807;0), i4 (502,-19807;-20000)
- unequal_zero_T i0 (-10507,9802;-10), i1 (-10502,9807;0), i4 (-502,19807;20000)

Require 4 healthy + 10 separately forced candidate runs, 70 physical gate crossings, exactly one forced event in each forced run (8 nonzero, 2 zero sham), seven-field comparisons. One IP, max 300000 candidate steps/run, 220-second watchdog/process; independent reference calls separately bounded. Include source/runtime hashes, raw receipt, logs and checksum manifest. Fail closed on missing crossings, unexpected count, source mismatch, unexpected output or timeout; no fabricated expected-red. Native execution NOT_RUN; arithmetic oracle planning 4/4 sums, 10 intervention inputs calculated, not Native or full Stage1 proof. NEXT: implement new CW harness and integrate with existing QA workflow without rerunning CV or CU on identical evidence. No main/merge or Stage2.
