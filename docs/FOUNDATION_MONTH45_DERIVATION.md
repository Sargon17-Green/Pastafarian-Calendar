# Foundation year: exact 45-month length selection

Source of normative rules: pinned `main@56bc4173aae4975ded019ef5ab5a36249f1424df`,
sections U, V and N. This is a **test-only independent reference**,
not a production SystemVerilog implementation or an approved source
language catalog.

**Source pair:** `(c,firstDayOfYear)=(-15055671,-15057702)`.
**Year length:** 4244 days.

1. `minMonths=ceil(4244/123)=35`;
   `maxMonths=min(47,floor(4244/4))=47`.
2. Bowl 3 seal 30 selects ordinal 11 of the 13 allowed counts,
   i.e. `m=45`.
3. Let `f(k,s)` count ordered k-tuples with each member in 4..123
   and sum s. Then
   `f(0,0)=1`, `f(0,s!=0)=0`, and
   `f(k,s)=sum_{a=4}^{123} f(k-1,s-a)`.
   The sliding-window recurrence computes each DP row in O(L)
   384-bit operations.
4. Independent closed-form cross-check: with
   `R=4244-4*45=4064`,
   `f(45,4244)=Σ_{j=0}^{⌊4064/120⌋}(-1)^j C(45,j)
   C(4064-120j+44,44)`.
   Result by **both** independently evaluated methods:
   `28267369127220710176329716843724118975520840014877906533654334421021017631241800900`.
   Hex: `3b999c3af2d83d8b41d8b6b0aa25e5fc7a260dcb4a823403855975a8c46102e640cc4`.
   **274 bits**.
5. With `M=2^127-1`, this count is greater than `M²`;
   hence the equal-selection choice needs **k=3 consecutive
   base-M answer digits** from bowl 3 seal 31. The original
   stream increments/decrements on the prescribed ring.
   The independent 1-based rank:
   `21706039149316943527912320903423885398156086660670683714452395033170314294340946533`.
   Hex:
   `2dc4103440a9bb51a98553c5d90d5b6b1e2b77cd88cf16203b5f39498173def210a65`.
6. Lex unranking: at each month, iterate candidate length a
   ascending 4..123. Its completion block size is
   `f(monthsRemaining-1,daysRemaining-a)`. Subtract blocks
   until the target rank falls inside one; select that a.
   Result: [`FOUNDATION_MONTH45_LENGTHS_REFERENCE.csv`](FOUNDATION_MONTH45_LENGTHS_REFERENCE.csv),
   all 45 entries between 4..123 with total 4244.

**Open and essential:** Source section V selects an entire *woven*
word over all 4244 days, subject to first/last appearance orders.
Do not turn the nominal length vector into adjacent blocks.
After the weave, each month name is selected by 47P45 unranking
using bowl 5 seal 33. Neither operation is completed here.
Canonical expected result for c=t=Foundation: month-name index 20,
day-in-month 56, both still unverified in this oracle slice.

**Execution status:** arithmetic calculation independently reviewed;
SystemVerilog DP/unrank code committed but its first CI completion
is outstanding. Do not report a Stage-1 PASS.
