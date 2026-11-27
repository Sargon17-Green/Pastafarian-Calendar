// 2026-11-27: pre-integration assessment of normative op57 (planned production op40).
// Run: node tools/preintegration_normative_contract_audit.mjs
// Reference pin 9072687bd0fc955a243c15285cdf96bf4cd53532
// Source: test/normative_reference.false blob 3e9acc012bedf83294a6ec3cccb081a069556b5b;
// op21 catalog: index 0=M, 1=1, 2=0, 3=-15055671, 5=720; op22 calls seqAt(index+1).
// op56 initializes T with constant index 2 (ZERO, not 2 or 6); then sums old bowls,
// adds 149*u, SAVE; rank is 1+((T-1) mod 720) from indices 1 and 5.
// Production op39 and accepted RUN_STAGE22.md instead use +6 and rank 4+((T-4) mod 7).
// op38 uses signed compare target/calculation, direction 2+sign; production f
// computes sign(target-calculation) then maps negative=3,equal=1,positive=2.
// Both discrepancies must be reconciled with the pinned normative specification
// before an integration gate. Historical bounded acceptance is not erased.
// No production or existing oracle edits. No Stage23 implementation/acceptance.
// Proposed contract of op57: two fully allocated canonical signed day BigInts,
// tuple [calculationDay,targetDay]; output direct [2,finalBowls,orderAt46].
// finalBowls=[6,B1..B6] canonical positives <=M in bowl-ID order;
// orderAt46=[6,o1..o6] permutation 1..6 from drop 46, NOT a batch order.
// Pipeline: workCounts f (norm38), stones op24 (norm42), hidden op29 (norm46),
// visible op31 (norm48), initial bowls op37 (norm54), visible evolution op38
// (norm55), final evolution op39 (norm56). Preserve orderAt46 through op39.
// Verify all dependencies against same-branch normative specification first;
// oracle: independent integer/permutation model, compare each intermediate and
// final 12 values, equal dates, both directions, epoch±1, large signed days,
// replay, canonicality, input immutability, shape, order preservation,
// fresh output ownership, semantic invalid headers, numeric mutation witnesses.
// Invalid physical pointers/truncated allocations remain excluded.
// Resource bounds from Stage22; integrated gate not run. Do not reuse a
// prior bounded oracle as normative evidence. No other branch fixture imported.
function audit(){
 const M=(1n<<127n)-1n;
 const save=x=>{if(x<=0n)throw Error("positive domain");return 1n+(x-1n)%M};
 const perms=a=>a.length===0?[[]]:a.flatMap((x,i)=>perms(a.filter((_,j)=>j!==i)).map(p=>[x,...p]));
 const P=perms([1,2,3,4,5,6]);
 if(P.length!==720||new Set(P.map(x=>x.join())).size!==720)throw Error("permutations");
 function evolve(input,mode){let b=input.map(BigInt),trace=[];for(let u=1n;u<=12n;u++){const t=save(b.reduce((a,x)=>a+x,0n)+149n*u+(mode==="reference"?0n:6n));const rank=mode==="reference"?1n+(t-1n)%720n:4n+(t-4n+7n)%7n;const o=P[Number(rank)-1];const next=b.map((v,i)=>{const p=o.indexOf(i+1),l=b[o[(p+5)%6]-1],r=b[o[(p+1)%6]-1];return save(v*v+3n*l+5n*r+t+u+BigInt((p+1)**2)+7n*l*r)});trace.push({t:String(t),rank:String(rank),order:o,values:next.map(String)});b=next}return {first:trace[0],final:trace[11].values}}
 const cases=[[2,3,5,7,11,13],[1,1,1,1,1,1]].map(input=>({input,reference:evolve(input,"reference"),acceptedContract:evolve(input,"accepted")}));
 if(cases[0].reference.first.values.join()!=="510,340,1327,591,432,660"||cases[0].acceptedContract.first.values.join()!=="529,349,853,394,878,599")throw Error("witness mismatch");
 if(cases.some(c=>c.reference.final.join()===c.acceptedContract.final.join()))throw Error("expected distinct final states");
 const direction=[-1,0,1].map(sign=>({sign,reference:2+sign,production:sign===0?1:sign===1?2:3}));
 if(direction.some(x=>x.reference===x.production))throw Error("direction witness");
 return {project:"PC-BRANCH-FALSE-ARABIC",base:"9072687bd0fc955a243c15285cdf96bf4cd53532",referenceBlob:"3e9acc012bedf83294a6ec3cccb081a069556b5b",productionBlob:"b4792087e9c46fbd1c79a51887b64e5ee0bf970d",scope:"static derivation and executable mathematical counterexamples; NOT Native/differential runtime acceptance",cases,direction};
}
console.log(JSON.stringify(audit(),null,2));
