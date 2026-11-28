# QA31AK — accepted bounded source writer/ingress review (2026-11-07)

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Source: frozen production Git blob 560d6aa5807a7f766213a33835cce85eab0fa40c
Exact corrected code HEAD: 8b4841ef6410766d89583e5872f6c79ac11e73d7
Production remains untouched. Review-only [skip ci] follow-up; no main/merge/Stage2.

## CI acceptance

Original QA31AK code commit: a2e25c018191bf0cf5b685a0290e8b56ee4cbba3.
Initial CI run 42307471942 completed/failure because the independent
oracle incorrectly expected p(152,26)/p(152,35) to write value 1
under the test premise c=(2,49)=0. The forward original-source result
shows those two writes carry value 0, while their memory destination
(10+q,49) is correct. Independent inspection checked 14 row26 and
14 row35 source-conditional cases. The correction changed exactly
two oracle constants (1 to 0); no source or production code changed.
Do not classify this harness expectation as a production bug.

Corrected exact-HEAD CI:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42307737649
Completed/success at 8b4841ef6410766d89583e5872f6c79ac11e73d7.
Job 128201248601: checkout, exact source Git SHA, Python compilation,
forward source interpreter, independent inverse and artifact upload all
completed/success.

Original GitHub Actions artifact:
https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/42307737649/artifacts/13546966874

ZIP SHA256: 3242ca278eaeb2d26cc5487827f3da64199104ec8990b822bdb916dd242f4de5
Size: 14224 bytes, 4 members (forward.json/log, inverse.json/log),
ZIP CRC PASS 4/4, exact ZIP SHA256 independently checked after download.
Persistent ChatGPT Library mirror:
 /Befunge_QA_Artifacts/QA31AK_BEFUNGE98_KYRGYZ_SOURCE_WRITERS_20261107.zip
(full source and independent scripts are reproducibly available as
GitHub files under the corrected code HEAD; the 14 KB artifact contains
the original CI JSON and logs, not a new Native binary).

## Measured finite facts

- Literal original source glyphs p: 57 total, 13 at y=0..44 and
  44 outside. The full coordinate list of the latter is included in
  forward.json; their execution/reachability and dynamic write targets
  are UNKNOWN, not proven irrelevant.
- For normalized empty-stack source row entries, original-source
  q=(1,49) writers: p(106,2), p(248,26), p(248,35).
  m=(3,49) writers: p(202,2), p(248,14), p(344,26).
  These are conditional source-model ownership statements only.
- 895 source-conditional entry probes independently inverted:
  768 byte parameter probes (256 each for rows5,8,17),
  126 q/m states (q=0..6, m=0/1 for nine rows), one row2 reset.
- Conditional original-source predecessors under normalized entry:
  row20 <- row17, row23 <- row20, row29 <- none of modeled
  nonnegative-byte entries, row32 <- row29. Source graph conditional
  edges do not prove physical incoming edges for arbitrary stack/IP.
- From initial q=0,m=0 and canonical nonnegative byte returns,
  exactly nine q,m states are closed under modeled transitions:
  (0,0),(0,1),(1,0),(1,1),(2,0),(2,1),
  (3,0),(3,1),(4,0).
  Every 0..255 byte was re-walked from all nine states: 2304/2304
  source-conditional byte transitions independently inverted.
  Under this bounded canonical model, q>3,m=1 is unreachable.
- Forward source-site mutations rejected 7/7; independent reverse
  mutated-report controls rejected 16/16; inverse source pins 15.
- No new Native execution or frozen historical Native re-run.

## Interpretation and explicit non-claims

This is a conditional, bounded source-model invariant, not global
unreachability for the 1.8 MB self-modifying original Funge-98
program. The model requires entry x=10, empty stack per modeled
row boundary, exact unchanged source, and nonnegative byte returns.
Alternative IP/vector/stack ingress, possible modifications from
outside the prologue and 44 outer p glyphs are not resolved. Nothing
proves that every physical trace follows this normalized grammar.
The full functional and geometric Stage1 gates remain OPEN; no
natural-input m=1 AND q>3 physical witness is established.

## NEXT — QA31AL

Use the new source-wide list of 44 out-of-prologue p glyph sites
to construct a bounded static opcode-neighborhood and address-
expression ownership audit: can a source-grounded alternative vector
or put target modify q=(1,49) or m=(3,49) or re-enter row20/23/29/32?
Use an independent reverse opcode/address oracle with hostile checks.
Where arbitrary stack/IP history is needed, return UNKNOWN instead
of a global impossibility claim. Reuse already-signed original traces
before proposing fresh Native. A new Native probe is justified only
after deriving and independently checking a concrete natural-input
candidate under 25000 STEP/case. Do not enter Stage2, merge or main.
