# QA31F: source-pinned natural ASCII-prefix q/m lineage — 2026-10-31

Project `PC-BRANCH-BEFUNGE98-KYRGYZ`. QA branch `qa-befunge98-stage1-order-isolation-20261008`. Original source blob `560d6aa5807a7f766213a33835cce85eab0fa40c` is immutable.

## Previously accepted evidence

The existing upper-band graph [run 41139507151](https://github.com/Sargon17-Green/Pastafarian-Calendar/actions/runs/41139507151), job 124350058793, completed/success on exact commit `728c68bb6d84113e0a0e9d9665961485a8e9a9b7`. Log: 1,440 standard-entry source-model cases and three hostile mutations rejected. **Not Native.**

## New contract and predicted observation (requires new exact-SHA CI to accept)

New independent `qa/stage1_qa31f_ascii_prefix_lineage.py` evaluates the original Befunge-98 upper-band instructions **from initial IP (0,0)** rather than assuming segment entries. It implements a finite input-prefix model, real original source characters, stack, `p/g/j/x/#/~`, and physical writer ancestry. It stops **before** an unprovided input byte, never inventing EOF. No `{ }` storage-offset instructions are executed in the probed corridors; offset zero is an explicit scope assumption, not a global proof.

Test matrix: three ASCII digits 0/1/9, four separators space/TAB/LF/CR, and repetition lengths 1..5, giving **60 bounded input-prefix models**, checked against a separately derived arithmetic oracle. Three damaged physical opcodes (j at 113,11; p at 248,14; p at 248,26) must be rejected by a changed behavior. Step cap: 16,000 per input. This is an **executable QA contract, not yet a PASS until CI completes**.

Example prefix `1 1 1 1 1 `: row11 observes q=0,1,2,3,4 with m=0; row20→23 traverses the whitespace bypass four times at q=0,1,2,3 and m=1. Source writer p(248,14) supplies m=1, while row26 increments q via p(248,26) and resets m through p(344,26). Fifth digit sees q=4 at row11 and routes to row44, before final whitespace is read. As a result q=4 with m=0, not a source-model witness for row23 q>3 and m=1.

## Evidence boundary and NEXT

This is not a Native run, not signed STEP revalidation, not all input bytes, not EOF normalization, not global no-self-modification or stack/storage-offset ownership, and not Stage1 PASS. Do not rerun unchanged QA20 48 traces or former 263 q-writer cases.

NEXT: only if there is a grounded natural stdin/EOF candidate, develop a bounded Native probe with independent STEP and lineage audit. Otherwise trace another substantive source-controlled ingress (including row35/41 or EOF), without labeling lack of a candidate a user-approval blocker. No main/merge/Stage2.
