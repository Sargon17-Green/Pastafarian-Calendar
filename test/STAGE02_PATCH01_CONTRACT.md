# Stage 2 - Patch 01: zero to M

PROJECT_ID: PC-BRANCH-FORTRAN-ENGLISH
Explicitly authorized 2026-11-28, Fortran+English only.
Discovery 01 accepted at 5a9c6387ef1a703e11bc5ddbbf7aa6111c94e6c6 (artifact 15221501754).
Historical function and accepted Discovery QA source remain unchanged. The historical QA is pinned to the Discovery commit and is not a current patch gate.

For signed arbitrary-precision x, M=2^127-1, execute oldRemainder once and retain rawRemainder in the invocation. Apply Patch01 exactly once: corrected remainder = M when rawRemainder=0, otherwise rawRemainder. The corrected field remainder is the current route output; no oracle import in production. Preserve bootstrap, phase 2/subphase 1, first two route markers, input and per-invocation ownership; append the Patch01 marker. No change to the clean oracle.

Independent analytic cases x=q*M+d for q=-2,-1,0,1,2,+/-10^40 and d=-2,-1,0,1,2. Expected raw is M+d for negative d and d otherwise; corrected output is M for d=0 and raw otherwise. Compare analytic result, independent test-only SAVE oracle, production raw and corrected values. Require 35/35 (7 corrected, 28 preserved), two isolation/reuse checks, 38 dispatch and validation calls, exactly one raw and patch call per invocation. Original 21 Discovery inputs are included; 14 additional neighbor cases. All canonical Stage1 regression gates remain unchanged. Exact checkout, 30s/1GiB native execution, stderr empty, exit zero, compiler, SHA256 and artifact. LAST_COMPLETED_STAGE remains 1 until evidence review; no Stage3/main/merge/release.
