# PC-BRANCH-LOGO-IDO — exact positive-remainder fastmod, QA only

Parent candidate: `96e18376fe043db17b32077f3e0551e034dce144`. Branch: `qa/logo-ido-wide-horner-fastpath-20261123`. Canonical Logo+Ido remains unchanged, Stage2 NOT ACCEPTED.

## Contract and mathematical proof
For positive integer X and positive divisor N, scan the base B=10000 digits of X from most significant to least. With remainder r starting at 0, process digit d as t=B*r+d. If t<N, set r=t without a quotient search. Otherwise, use the existing exact `bi.mag.qdigit` and keep only its remainder. Inductively, r is congruent to the processed prefix modulo N, 0<=r<N. Further, 0<=t<B*N, so the original `bi.mag.qdigit` bound holds. The final r is exactly X mod N. Both call sites receive nonnegative X (`space` and `rankSample-1`) and positive canonical N. The fastpath for N>space/2 and acceptance/rejection semantics are not changed.

This reduces unnecessary quotient-list construction and binary searches for a zero quotient digit. Expected benefit is largest when N has nearly as many digits as space, notably N=M^(k-1)+1 for k=32,33,64. No blanket speed bound for arbitrary N is established.

## Exact-SHA evidence and acceptance
Parent `96e18376fe043db17b32077f3e0551e034dce144`: Native smoke run 45083211141 k4 (four cases) and k64 (one case) completed SUCCESS with exit 0 and independent Python ranks; Names Lock 45083210955 SUCCESS. Artifacts 14778760489 and 14778750836, provider digest SHA256 b6cb7f65017d30bdbf5132aa6a0af0c5d81e6daf08292589e1eb018e628e95b7 and 489e81d860d139ded05a8acb96919b8d129d1be8ed79e8f8a81c1e48b7a4ee53 (not independently rehashed).

The new source SHA must requalify all six original exact-width Native QA shards k4,5,6,32,33,64, with Python arbitrary-precision independent oracle, 18 invalid-input guards per shard, exact counters 34 or 38 assertions, pinned UCBLogo 6.2.5, source lock and per-job artifacts. The existing k4/k64 smoke is also source-relocked for regression. A new CI run may be queued/in_progress and cannot be counted as PASS without completed job/log/exit/artifact. The bounded Native execution limit is 300s for k4-6 and 900s for k32/33/64. Failures require case-marker isolation and a new diagnostic; do not rerun unchanged source without evidence.

No canonical promotion, main/merge, policy change or Stage2 acceptance is authorized by this QA-only work.
