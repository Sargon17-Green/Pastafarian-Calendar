# Stage1 bowls — independent host contract

## Normative source and measured contract

Source of truth is the pinned README `56bc4173aae4975ded019ef5ab5a36249f1424df`, sections J–K. The oracle is `tests/test_sm83_stage1_sauce_oracle.py`.

For each visible iteration (i=1..46):

- Inputs: visible residue (D_i), five-stone snapshot (S_i[0..4]), six old bowl residues (B[1..6]), and the lexicographic order (pi_i).
- Rank: (r_i=1+((D_i-1)mod720)); (pi_i) is the (r_i)-th lexicographic permutation of ((1,2,3,4,5,6)).
- Direct pours, for positions (q=1,2,3), with identity (b=pi_i[q]): (P_q=SAVE(D_i^2+S_i[q-1]B[b]+(2q+1)i)).
- For each position (q=1..6), (b=pi_i[q]), (p=pi_i[q-1]), (n=pi_i[q+1]), with cyclic neighbors. Every read is from the same frozen old tuple:
  (u=B[b]+2B[p]+3B[n]+(qle3?P_q:0)+D_i+S_i[(q-1)mod5]).
  (B'[b]=SAVE(u^2+5B[p]B[n]+iq)).
- Atomicity: compute all six outputs into a separate new tuple, then replace the old tuple once. No bowl read may observe another bowl's new value.

For post-stir (r=1..12):

- (S_r=SAVE(sum_{b=1}^{6}B[b]+149r)), computed from the pre-stir snapshot.
- Use that same retained (S_r) both for (pi_r=lex_order(S_r)) and in every (u=B[b]+3B[p]+5B[n]+S_r+r+q^2).
- (B'[b]=SAVE(u^2+7B[p]B[n])), again with all six reads from the same pre-stir snapshot.
- Retain all twelve (S_r) values; do not substitute the raw sum in either the permutation rank or (u). Preserve (pi_{46}) independently for the later seal/direction contract.

## Independent validation added

`tests/test_sm83_stage1_bowls_abi.py` checks 72 ordinal pairs, including signed32 endpoints, c<t/c>t, and the ten source-derived fixture pairs. It independently reconstructs all 46 stone states, all 46 bowl snapshots, and all 12 post-stir snapshots; checks all 720 factoradic permutations against the lexicographic permutation table; and checks a bit-serial 128-bit modulo-720 routine against Python's exact modulo.

This is a Host oracle/contract gate, not Native acceptance. No SM83 bowl runtime is claimed by this document. Native work remains: implement 128-bit modulo-720 plus factoradic unranking, six simultaneous bowl updates, twelve post-stirs and retained (S_r), then test the final (pi_{46}), bowl tuple and retained sums before A0/direction.
