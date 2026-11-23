# Issue #29 / v186 — original Ada ticket-stream reachability

**Scope: source-mathematical QA only; no calendar F, no native converter, no soak.**

## Original source lineage (verified)
- Ada original commit \`a2fb6811ce8c1c4aa3e2d0dffc9f2ea549803b72\`, \`src/normative_oracle.adb\` Git blob \`923733d4f8face03586aee304640bf7540c28b4c\`; \`src/month_weaving.adb\` Git blob \`9b02c62dfbc7d8b3b532aba8cd9f1ad0f8b28fef\`.
- Python original commit \`0e4e75886dea4f4c7e0b6e39cce79e1d66f046f4\`, \`tests/normative_reference.py\` Git blob \`d58298c6b7be58fc1d1e2d64a0d203b7c42e4d53\`.
- Ada original source: \`Choose_Month_Weaving\`, lines 1082–1122, generates each interior ticket from a **single cyclic stream** shifted by index; \`Month_Weaving.From_Choices\` rebuilds a fixed-rail multiset. Python source lines 1137–1144 globally ranks all canonical legal weaves. This difference was already known; the present audit proves a further *ticket correlation* restriction.

## New theorem
With original modulus \(M=2^{127}-1\), initial stream answer \(x\in[1,M]\), direction \(d\in\{-1,1\}\), interior ticket count \(K\), and local slots \(s_i=K-i\), original Ada chooses \`ticket_i\` from \`1+((x-1+d*i) mod M)\` after bounded cyclic rejection. In the safe region \(2K+1\le x\le M-2K\), no wrap/rejection is possible; therefore
\[
  ticket_i-1\equiv x-1+dK\pmod{s_i}.
\]
For even \(K\), tickets \(i=0\) and \(i=2\) have the **same parity**, since \(K\) and \(K-2\) are even.

**Whole-year-valid synthetic counterexample:** month lengths (84,84,84), total year length 252, month count 3 (within permitted bounds). A canonical, legal fixed-rail weave begins with opening rail (1,2,3), has interior \`(1,2,2)+(1 repeated 81)+(2 repeated 80)+(3 repeated 82)\`, and ends with closing rail (1,2,3). Its first three inverse tickets are **(1,82,82)**. Their parities violate the above invariant for \(K=246\). Every excluded first answer lies in the finite boundary \`[1,492] union [M-491,M]\`: **984** first answers per direction, **1,968** total. All boundary streams were exhaustively evaluated: **0** generate this ticket prefix. Consequently, this legal 252-day fixed-rail weave is unreachable by the original Ada stream mechanism for **all** initial values and both directions. Byte-label SHA-256: \`d6467e288ea79380073e1acbbc5bd190b38ce3a102abeb227782c12dc468976c\`.

**Small exhaustive control (4,4,4):** full canonical family has 1,301 weaves (enumerated from all 34,650 distinct fixed-multiplicity words); fixed-rail family has 90, but only **40/90** are reachable by the correlated original Ada tickets. Completeness follows from exactly \`lcm(1..6)=60\` safe-region residue classes plus both bounded edge zones. Another **9,252** tiny-modulus cases independently compare the closed-form acceptance endpoint with a literal cyclic walk.

Reproduce: \`python3 qa/issue29/v186_ticket_stream_reachability.py\`; no third-party packages or original calendar code required.

## Limits
No original Ada or Python F(c,t) invoked, no native run/CI job dispatched by this QA source file. This strengthens structural non-equivalence **but does not identify the first actual intermediate divergence on foundation day** or causally explain observed month-name index 30 vs 20. Those fourth-field values are name indices, not month count. Issue #29 remains OPEN, \`STOP_NEW_NATIVE_SOAK_DISPATCH=true\`, original full years certified 0/10,000. No production changes or merges.
