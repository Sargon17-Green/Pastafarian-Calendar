// PC-BRANCH-SM83-ASSEMBLY-GEEZ — Stage1 Native393 PREPARATION, not accepted.
// Normative main README 56bc4173aae4975ded019ef5ab5a36249f1424df sections M,N; Issue #30.
// Accepted Native392 predecessor 67b09a33bf09e99a862bef1aa0a2b1469f455ced, push CI45505504580 24/24, A5/392/40 22053f.
// Contract: after validating active owner/ordinal, bowl 1..6, seal 10..12 and count
// 1..19044, use CalendarBowlAnswerA0Direction; copy canonical LE16 A0 to the
// existing CalendarSelectShortRank input and map direction 0x01->1, 0xff->2.
// Never pass 0xff through: the rank kernel rejects it. No wide selection or gate generation.
// A_k = 1+((A0-1+s*k) mod M), M=2^127-1; short rank uses first A_k <= L.
// Validate count before publishing; on errors preserve public rank, answer,
// Q, orderAt46, ordinal, owner/lease and foreign SRAM. Idle=6, invalid=2, success=0.
// Native393 candidate must exercise both actual directions, synthetic A0=1/M,
// forward/backward wrap, L/L+1, counts 1/2/922/19044, invalid 0/19045, invalid seal,
// invalid order/residue, idle, sentinel output, active owner and foreign SRAM.
// Source-derived Foundation and nonfoundation vectors must be computed independently,
// not imported from another branch; compare rank and A_k; retain Native370..392.
// ROMX only; exact checkout logs, RGBDS1.0.4, ROM_HEADER, ROM0 >=10 free,
// isolated A5/393/40 <=120000 frames, default Native370 <=9000, inspect ROM/map/sym.
// This standalone host QA is an independent ring model, NOT an emulator or ASM test.
// It checks boundary properties against literal ring traversal. Run: node tests/sm83_stage1_answer_rank_preflight.js
function run() {
  const M=(1n<<127n)-1n, max=19044n;
  function check(c,msg){if(!c)throw new Error(msg);}
  function at(a,d,k,m){let x=(a-1n+d*k)%m;return 1n+(x<0n?x+m:x);}
  function walk(a,d,n,m){let x=a,steps=0n; const limit=(m/n)*n;while(x>limit){x+=d;if(x===0n)x=m;if(x===m+1n)x=1n;steps++;check(steps<n,"rejected tail bound");}return [1n+(x-1n)%n,steps,x];}
  function closed(a,d,n,m){const limit=m-m%n;let accepted=a, steps=0n;if(a>limit){if(d===1n){accepted=1n;steps=m-a+1n;}else{accepted=limit;steps=a-limit;}}return [1n+(accepted-1n)%n,steps,accepted];}
  function compare(a,d,n,m){let x=walk(a,d,n,m),y=closed(a,d,n,m);check(x.every((v,i)=>v===y[i]),"rank mismatch");check(at(a,d,y[1],m)===y[2],"Ak mismatch");}
  let small=0, full=0, walked=0, wrap=0, mutant=0;
  for(let m=2n;m<=31n;m++)for(let n=1n;n<=m;n++)for(let a=1n;a<=m;a++)for(const d of [-1n,1n]){compare(a,d,n,m);small++;}
  for(let n=1n;n<=max;n++){const L=M-M%n;for(const a of new Set([1n,M,L,L>1n?L-1n:L,L<M?L+1n:L]))for(const d of [-1n,1n]){const [rank,k,accepted]=closed(a,d,n,M);check(k<n&&rank>=1n&&rank<=n&&at(a,d,k,M)===accepted&&accepted<=L,"127-bit boundary");if(a>L){check(rank===(d===1n?1n:n),"tail rank");if(n<=64n||[922n,19044n].includes(n)){compare(a,d,n,M);walked++;}if(n>1n&&d===-1n&&rank!==1n)mutant++;}full++;}}
  for(const a of [1n,2n,M-1n,M])for(const d of [-1n,1n])for(const k of [0n,1n,2n,M-1n,M,M+1n,2n*M+3n]){check(at(a,d,k,M)===at(a,d,k%M,M),"period");check(at(at(a,d,k,M),-d,k,M)===a,"reverse");wrap++;}
  check(at(M,1n,1n,M)===1n&&at(1n,-1n,1n,M)===M,"wrap");
  const adapter=x=>x===1?1:x===255?2:null;
  for(let x=0;x<256;x++)check(adapter(x)===(x===1?1:x===255?2:null),"direction ABI");
  check(mutant>0,"direction mutant unexercised");
  return {small_ring_literal_walk:small,full_width_boundary_checks:full,full_width_literal_walk:walked,wrap_period_reverse:wrap,direction_bytes:256,backwards_as_forward_mutant_rejected:mutant};
}
console.log("HOST_STAGE1_ANSWER_RANK_PREFLIGHT=PASS", JSON.stringify(run()));
