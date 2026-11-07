# QA31AR — signed original 200-case memory-value provenance for dynamic source opcode

PROJECT_ID: PC-BRANCH-BEFUNGE98-KYRGYZ
Branch: qa-befunge98-stage1-order-isolation-20261008
Verified incoming HEAD: 7fcca0f02dd65f2f9c0d85bdfef8230c02aaeaab
Original production Git blob: 560d6aa5807a7f766213a33835cce85eab0fa40c
Date: 2026-11-07

## Source evidence and original signed receipts

Immutable original QA31AI signed 200-case archive:
\`/Befunge_QA_Artifacts/QA31AI_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_PREFIX_20261106.zip\`
SHA256 \`9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49\`.

Full independent read-only source+signed-gzip validation: eight nested original
QA31V shard SHA256s, 200 raw-stdin/trace SHA256/HALT receipts,
3,628,390 contiguous STEPs and every signed next→IP transition. No
fresh Native executions or new full-corpus GitHub CI. Production unchanged.

The immutable source was independently fetched by exact Git blob ID and
the following original byte sequences were pinned at their original
coordinates; each executed opcode/pre-/post-stack was checked against
the original signed Native trace.

## Two original source transformations

**1. Initial memory owner:** p(280,860) stores the initial value at
M=(29,1698). It is physically executed in all 140 original cases
that reach the self-modifying routing phase. Among **100 natural
inputs whose final two raw bytes are ASCII digits**, the initial
numeric value written at p(280,860) equals their two-digit decimal
number, 100/100. This is an observed finite mapping; the entire
stdin-to-initial-value parser is not globally proved here.

**2. Decimal digit-step update:** g(664,1050) reads M. Following the
46-opcode source ray from x=664..634 on y=1050 and x=385..399 on
y=195, p(399,195) rewrites the same M with
\`M_new=trunc(M_old/10)\`. Both independent interpreters
source-check the literal byte sequence
\`ga/2a*9+02a*4+a*9+-08a*5+a*5+-x>1a*6+a*9+a*8+p\`.
The recorded older M is always a nonnegative integer in these
traces, so \`trunc(M/10)=floor(M/10)\`. The actual signed memory
update owner and all pre/post stacks match this equation in
**225 of 225 physically executed updates**. The two original
source sites writing to M in this corpus are only p(280,860) and
p(399,195); no third physical writer was observed.

**3. Source-opcode byte selection:** g(196,1335) reads the current M
with signed pre-stack \`[1,29,1698]\`. The unchanged 57-opcode
source suffix (37 x-direction cells and 20 y-direction cells)
executes:
\`g!*!78**6a*2++1a*5+a*01a*1+a*0+a*3+0xv+a*0+1a*7+a*5+a*0+p\`
It computes the source-modifying p(1335,1354) target=(1500,1750)
and its data \`B=62+56*int(M!=0)\`. Its two results are exactly
ASCII 62 (\`>\`) when M=0 and ASCII 118 (\`v\`) otherwise.
Original source byte at target (1500,1750) is space/ASCII 32.

All **365/365** source-read→source-put original event chains have the
signed g→put gap **56 STEPs**, exact original source path, exact
stack pre/post state, and matching last M writer. Count by
M owner at read: **140** at p(280,860), **225** at p(399,195).
Count by newly written B: **140** \`>\` / **225** \`v\`. These
are two *distinct* count partitions; do not confuse owner with
the ASCII class.

## Relation to existing signed control-flow evidence

The frozen QA31AQ original cases were cross-checked by signed trace
SHA256/raw input and exact 365 source selector p event values/STEPs;
**200 of 200 case receipts and 365 of 365 code-byte events match**.
The same original QA31AQ corpus contains **1,800 j(185,8)**
executions: 700 with operand 0 and 1,100 with operand 61.
This joint correspondence is observational and does **not** prove
the complete upstream causal influence of j(185,8) on initial M
for arbitrary natural input.

## Acceptance / artifacts

The two standalone source/trace validators use different numeric
implementations and independently reconstruct all 200 original
signed traces, memory owner histories, 225 decimal-update
paths and 365 dynamic source-byte paths. The second validator
rejects **18/18** intentionally corrupted report variants.

Permanent reproducible *evidence* ZIP:
\`/Befunge_QA_Artifacts/QA31AR_BEFUNGE98_KYRGYZ_SIGNED_MEMORY_CODEBYTE_AUDIT_20261107.zip\`
Size 38,490 bytes. SHA256
\`fda420633fea3e9fc869504fd7b50672af692b7b0016da18d517c20ab0ec2253\`.
11 ZIP entries, CRC 11/11, 10/10 manifest-member SHA256 checks.
Contains complete verifiers, 200 raw input receipt references, all
365 code write events, memory writer chains, original source pins,
separate original j source cross-correlations, logs and summary.
The original 46MB signed input archive is not copied into the small ZIP.
The scripts are an evidence reproducibility appendix, **not a
Windows user-execution package**; no user action is required.

This is **QA31AR PASS for a bounded original signed 200-case memory
and source-opcode dataflow reanalysis**. The 57/46-opcode arithmetic
facts are conditional on their unmodified source paths. No proof that
other natural input cannot enter the middle of either ray,
self-modify relevant source, produce an unexpected initial memory
value or reach an outer p site through another route. NO independently
verified new raw-stdin causing counter-target put to q=(1,49) or
m=(3,49) was derived. Stage1 global/functional/geometric remains OPEN.
No main/merge/Stage2 or new Native/CI.

NEXT QA31AS: trace original raw-stdin parser and source/data dependencies
creating the initial M=(29,1698) at p(280,860), including non-digit
and EOF cases in the existing 200 receipts. Pair input bytes with
bounded source parser instructions, memory read/write owners, and
j(185,8) route decisions using independent signed/byte oracle.
Distinguish conditional parser formula, physical execution and
global path coverage. Only a *concrete independently checked new
natural input* may justify further Native <=25,000 STEP per case;
otherwise retain UNKNOWN. Stage1 OPEN.
