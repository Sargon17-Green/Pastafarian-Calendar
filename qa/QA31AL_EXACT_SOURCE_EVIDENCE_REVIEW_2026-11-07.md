# QA31AL — exact-source conditional outer writer and ingress evidence review

Date: 2026-11-07
PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
QA branch: qa-befunge98-stage1-order-isolation-20261008
Pre-QA31AL HEAD: 9094e8fe7ffa512ee242392ab480eba89553ee87
Accepted tested code commit: 0750f51d934e9aa6367cb7536b9673e1b8f92660
Frozen original source blob: 560d6aa5807a7f766213a33835cce85eab0fa40c

## Acceptance evidence

GitHub Actions exact-commit run 42343966029:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42343966029
Status completed/success, job 128317561473 completed/success.
Exact Git hash-object, Python compilation, original source forward
and independent source-address/seeded oracle all PASSED.

GitHub Actions artifact 13562054951:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42343966029/artifacts/13562054951
ZIP size 2660 bytes; SHA256:
512a38aa508b9bf926b6db5014853f5ed44db3d5bf2767c8cbac7508ec18777b
Independently downloaded and checked SHA256 exact, four ZIP members
forward.json/inverse.json/forward.log/inverse.log, CRC 4/4 PASS.
Permanent evidence mirror in ChatGPT Library:
 /Befunge_QA_Artifacts/QA31AL_BEFUNGE98_KYRGYZ_OUTER_WRITER_EVIDENCE_20261107.zip

## Source-only facts (not dynamic reachability)

Exactly 57 raw original source 'p' glyphs, 13 control prologue
(y<45) and 44 original sites outside. 43 outer sites have ONE
qualifying unmodified-source straight corridor from a matching arrow
<=60 cells away, with only pure deterministic stack arithmetic in
between. Site [369,575] has no qualifying bounded corridor.

Using symbolic stack interpretation with all incoming items treated
as arbitrary UNKNOWN (not 0), 11 of those 43 corridors give a
constant top-of-stack y value not equal 49. Under each SPECIFIC
straight entrance, with unmodified source and no intervening vector
turn, that corridor cannot address q=(1,49) or m=(3,49).
The 11 precise source (x,y) p sites and static target y values:
(399,195)->1698; (1030,385)->1705;
(860,846)->1691; (405,860)->1701;
(195,1036)->1715; (480,1070)->1704;
(876,1240)->1699; (986,1334)->1600;
(1335,1354)->1750; (1430,1540)->1716;
(670,1598)->1708.

32 accepted corridors have y=UNKNOWN for arbitrary pre-entry stack.
These 32 are NOT shown to write to y=49; they are simply not excluded.
The unanchored site is also UNKNOWN. All 44 global physical p
write targets remain UNKNOWN without a signed execution or a stronger
whole-program invariant. An alternate vector or self-modification
can bypass even the 11 conditional local exclusions.

Control entries (10,20), (10,23), (10,29), (10,32) contain
original source '>' with empty-source-line north/south neighbors
(padding spaces in Funge playfield) and blank west neighbor. Thus
a hypothetical direct incoming north/south/west IP can be redirected
east at these locations. No source-only proof establishes whether
any natural input produces such an incoming IP.

## Quality checks

Forward: 10/10 mutated original p-site source controls rejected.
Independent inverse: every one of 44 original site coordinates and
all 43 corridor-source byte sequences and cardinal directions
validated against the frozen source; 11 exact static-y values pinned;
215 separate concrete seeded stack corridor interpretations performed
as supplementary checks; 14/14 hostile tampered reports rejected.
Concrete seeded examples do not replace the abstract proof for
arbitrary initial stack; the symbolic propagation is the source
of the 11 conditional exclusions.

No new original Native runs, and no re-run of historical Native.
No production changes, no main/merge/Stage2.
Stage1 global, functional and geometric gates remain OPEN.
This acceptance is QA31AL FINITE SOURCE-CONDITIONAL ONLY.

## NEXT: QA31AM

Characterize remaining 32 conditional unknown-y corridor
address expressions and the no-anchor site (369,575) by bounded
source-grounded stack/instruction predecessor analysis. Investigate
possible vector/stack histories reaching the four noncanonical
counter-row ingress points without inventing a witness. If exact
write targets need arbitrary incoming stack or dynamic self-modifying
code, preserve UNKNOWN and look first at already signed original
Native evidence. No new Native unless independently checked
concrete natural input, <=25000 STEP/case. Stage1 OPEN.
