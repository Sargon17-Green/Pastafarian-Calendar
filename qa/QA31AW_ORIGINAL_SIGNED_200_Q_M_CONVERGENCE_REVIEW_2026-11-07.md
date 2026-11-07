# QA31AW — original signed digit/delimiter counter convergence and source algebra (2026-11-07)

**PROJECT_ID:** `PC-BRANCH-BEFUNGE98-KYRGYZ`  
**Branch:** `qa-befunge98-stage1-order-isolation-20261008`  
**Verified incoming HEAD:** `dc3a87f4939b43c316251331727a5e8780ba24e1`  
**Immutable original production Git blob:** `560d6aa5807a7f766213a33835cce85eab0fa40c`  
**Immutable original signed QA31AI ZIP SHA256:** `9e9d4a8d058f91046e9c7d35cd68270ddf1e4676fe3bbd9917033785dcf17f49`

## 1. Exact original source-pinned local effect theorem

Three complete original straight source rows were independently read from
the ORIGINAL Git blob, with byte-for-byte equality and exact SHA256 of each
source slice verified. None was modified by any physical `p` in the frozen
200-case corpus.

| Source region | Bytes/opcodes | Original source slice SHA256 | Signed original traversals |
|---|---:|---|---:|
| `y=14, x=10..248` digit route | 239 | `a31cd8d5704a346cfcec47ac94cf68a1ab15566dc5c202d4ba6c824a5983d7df` | 1,060 |
| `y=26, x=10..344` separator route | 335 | `dfde5ecd243b54d282d3f439fce299951435462f8eaa576d126570b85df9a192` | 680 |
| `y=35, x=10..248` post-EOF route | 239 | `af3f2c50916555cd83dd34c877b84244f8808a59ad722f84fdee4ee0330aba0d` | 100 |

Let `q=mem(1,49)`, `m=mem(3,49)`, `n=mem(2,49)`,
and `b=mem(0,49)` at each source-ray entry.

**Row14 digit route**, conditional on the complete unchanged original
source suffix and its normal stack operations:
- `p(200,14)` writes `n' = 10*n + (b - 48)` to (2,49);
- `p(248,14)` writes `m=1` to (3,49);
- q is unchanged by these two source writes.

**Row26 delimiter route**, when `q>=0` and the complete source
suffix is traversed:
- `p(152,26)` writes the current `n` to **(10+q,49)**;
- `p(248,26)` sets `q'=q+1`;
- `p(296,26)` clears `n=0`;
- `p(344,26)` clears `m=0`.

**Row35 post-EOF final-number route**, when `q>=0` and its complete
source suffix is traversed:
- `p(152,35)` writes current `n` to **(10+q,49)**;
- `p(248,35)` increments `q'=q+1`;
- this happens **after** the row32 q>3 gate and cannot retroactively
  open that gate.

An independent symbolic RPN source interpreter enumerated 2,106
source-expression tests over signed and unsigned representative memory
values, and the original signed engine verified **every stack
transition in 505,040 original-source executed instructions** along
these three rows. Unlike a previous naive 'save at (10,49)'
assumption, the address **varies with q**.

**Important algebraic caveat:** the row26/row35 q-increment theorem is
conditional on avoiding address aliasing. For hypothetical `q=-9`,
the staging put target (10+q,49) is the **q cell (1,49)** itself.
With `n=12`, source instructions overwrite q with 12 before the
later q read, and the final value becomes **q=13**, *not* -8.
The second symbolic oracle explicitly verifies this counterexample.
The original 200 signed cases have nonnegative q; this caveat
prevents an unjustified all-stack/global statement.

## 2. Actual 200-case signed Native counter state

Two implementations independently read all eight immutable nested
QA31V shards with SHA256/HALT and per-input gzip SHA receipts, and
**3,628,390 contiguous original STEPs** with next→IP. Their original
signed-case event ledgers agree for all **5,040 actual source p
events** over those rows, including source IP, signed tick, computed
target (including (10+q,49)), new value and preceding memory value.

The partition of 200 **physical natural inputs** is:

| Original frozen trace group | Cases | pre-row32 q,m state | Last owner |
|---|---:|---|---|
| Reaches EOF and row32 | 100 | `q=3,m=1` | q via `p(248,26)`, m via `p(248,14)` |
| Reaches EOF but skips row32 | 40 | `q=4,m=0` | q via `p(248,26)`, m via `p(344,26)` |
| HALT before EOF | 60 | no physical postEOF row32 gate | n/a |

Original row14 had 1,060 complete physical traversals,
row26 680, and postEOF row35 100. Original q/m canonical writes
were 2,920 across the entire corpus (as in QA31AV). The 100
row35 increments from q3 to q4 occur **after** the q>3 gate
evaluated q=3, and cannot be counted as gate crossings.

There is **NO observed original signed input** with m=1 and q>3
at the row32 gate. This finite negative result is not a theorem
for all natural inputs.

## 3. Local compatibility vs concrete physical natural-input witness

The source formulas, under their explicit unchanged-source/normal
entry conditions, permit the hypothetical transition

`(q,m)=(3,1) --delimiter row26--> (4,0)
 --digit row14--> (4,1)`.

This **refutes any claim that these numeric values are mutually
exclusive by the local arithmetic alone**. It is NOT a physical
proof that the original input parser will re-enter both routes
under those precise conditions.

A deliberately **UNVERIFIED** candidate raw input is
`3120302030203030302030` (ASCII `1 0 0 000 0`), formed
by appending a SPACE and digit 0 to a previously signed input
`312030203020303030` (ASCII `1 0 0 000`).
The new 11-byte input was **not** executed in original Native,
and no full source-flow/stack theorem currently certifies its
path, dynamic memory state, termination, or <=25,000 STEPs.
It is stored solely as a test hypothesis. No original Native
execution is authorized by this hypothetical expression alone.

## 4. Independent reproducibility and adversarial controls

New QA evidence archive:
`/Befunge_QA_Artifacts/QA31AW_BEFUNGE98_KYRGYZ_SIGNED_200_COUNTER_CONVERGENCE_20261107.zip`

- ZIP SHA256 `900d0108b5967934b70de4df278f4fa2464d8ed7757cb47fc563f1526759256e`;
- 51,292 bytes, **12/12 ZIP CRC and 11/11 manifest-member
  SHA256** verified; mirrored successfully to persistent Library;
- includes two **independent** complete original signed
  input/gzip/STEP readers (second imports no first reader code),
  structural RPN oracle with explicit negative-q alias test,
  all 200 case source/writer events, compact case CSV, source
  SHA pins checked live against original Git blob, an explicitly
  unverified input hypothesis, original execution logs, and README_HE;
- independent oracle rejects **26/26 real non-no-op
  synthetic report mutations**.

Previous missing archive delivery was repaired separately: the
verified QA31AV 71,139-byte ZIP SHA256
`7efd888ed86751749499ebf8c835e4a5cdd7257ac9fc96463cd86c4219a9e862`
was successfully copied to Library path
`/Befunge_QA_Artifacts/QA31AV_BEFUNGE98_KYRGYZ_ORIGINAL_200_POST_EOF_COUNTER_AUDIT_20261107.zip`.

This is **QA31AW PASS for a bounded conditional source theorem
plus finite original signed 200-case replay only**. Original
source and main unchanged, zero new Native runs, zero new
full-corpus GitHub CI runs. Stage1 global, functional,
geometric **OPEN**; unobserved IP paths and self-modification
remain UNKNOWN.

## NEXT — QA31AX

Constrain the specific NEW proposed input
`3120302030203030302030` via independent original-source
input-loop re-entry and mutable source-state proof:
start from the source-pinned 40 signed separator-at-q3 cases
where row26 creates `q4,m0` and returns to `~(13,5)`;
prove or refute physical routing for next digit 0, including
original-byte/stack memory dependencies, source mutation
constraints and 25,000-step termination cap. Check with a
different source/receipt oracle and adversarial controls.
Only after a concrete independent source-and-input proof
may original Native be run (<=25,000 STEPs/case). If proof
does not close, retain UNKNOWN and no Native, no main/merge/Stage2.
