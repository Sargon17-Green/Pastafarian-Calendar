// Independent host enumeration and lexicographic-block fixture oracle.
import {writeFileSync} from 'node:fs';
function makeFixture(){
 const total=(n,k)=>{let p=1n;for(let i=0;i<k;i++)p*=BigInt(n-i);return p};
 // Oracle: count lexicographic prefix blocks, not mixed-radix extraction.
 function oracle(n,k,r){let pool=Array.from({length:n},(_,i)=>i+1),out=[];for(let i=0;i<k;i++){const block=total(n-i-1,k-i-1);let pos=0;while(r>block){r-=block;pos++}out.push(pool.splice(pos,1)[0]);}return out}
 function model(n,k,r){let x=r-1n,d=[];for(let b=n-k+1;b<=n;b++){d.unshift(Number(x%BigInt(b)));x/=BigInt(b)}let p=Array.from({length:n},(_,i)=>i+1);return d.map(i=>p.splice(i,1)[0])}
 function rank(n,ids){let p=Array.from({length:n},(_,i)=>i+1),r=0n;for(const id of ids){let i=p.indexOf(id);r=r*BigInt(p.length)+BigInt(i);p.splice(i,1)}return r+1n}
 let enumerated=0;
 function walk(n,k,pool,ids,state){if(ids.length===k){state.r++;const expected=ids.join(",");if(oracle(n,k,state.r).join(",")!==expected||model(n,k,state.r).join(",")!==expected||rank(n,ids)!==state.r)throw Error("enumeration mismatch");enumerated++;return}for(let i=0;i<pool.length;i++)walk(n,k,pool.filter((_,j)=>j!==i),[...ids,pool[i]],state)}
 for(let n=1;n<=7;n++)for(let k=1;k<=n;k++)walk(n,k,Array.from({length:n},(_,i)=>i+1),[],{r:0n});
 const bi=x=>{if(x===0n)return "(bi.zero)";let sign=x<0n?-1:1,d=[];if(x<0n)x=-x;while(x){d.push(String(x%10000n));x/=10000n}return `(bi.make ${sign} [${d.join(" ")}])`};
 let lines=[`load "src/exact_integer.logo
load "src/stage02_context.logo
load "qa/logo_stage2_names_candidate.logo
make "QN.CASES 0
make "QN.CHECKS 0
make "QN.FAIL 0
to qn.check :ok :tag
 make "QN.CHECKS (:QN.CHECKS + 1)
 if not :ok [make "QN.FAIL (:QN.FAIL + 1) print sentence [NAMES_QA_FALIIS] :tag]
end
to qn.valid :n :k :r :expected :tag
 make "QN.CASES (:QN.CASES + 1)
 print sentence [NAMES_QA_CASE] :tag
 localmake "got qnames.unrank :n :k :r
 qn.check (equalp :got :expected) (list :tag [unrank])
 qn.check (equalp (qnames.rank :n :expected) :r) (list :tag [rank])
 qn.check (equalp (qnames.rank :n :got) :r) (list :tag [roundtrip])
end
to qn.bad :got :tag
 make "QN.CASES (:QN.CASES + 1)
 print sentence [NAMES_QA_CASE] :tag
 qn.check (equalp :got []) :tag
end
`];
 let valid=0;
 for(const [n,k] of [[17,1],[17,17],[47,1],[47,2],[47,25],[47,47],[7,3]]){const t=total(n,k);for(const r of [1n,(t+1n)/2n,t]){const ids=oracle(n,k,r);if(model(n,k,r).join(",")!==ids.join(",")||rank(n,ids)!==r)throw Error("boundary mismatch");valid++;lines.push(`(qn.valid ${n} ${k} ${bi(r)} [${ids.join(" ")}] [v${valid}])`)}}
 const bad=[
  ['(qnames.unrank 0 1 (bi.small 1))','n0'],
  ['(qnames.unrank 48 1 (bi.small 1))','n48'],
  ['(qnames.unrank 17 0 (bi.small 1))','k0'],
  ['(qnames.unrank 17 18 (bi.small 1))','k18'],
  ['(qnames.unrank 17 1.5 (bi.small 1))','fraction'],
  ['(qnames.unrank 17 1 (bi.zero))','rank0'],
  ['(qnames.unrank 17 1 (bi.small -1))','negative'],
  ['(qnames.unrank 17 1 (bi.small 18))','rank_over'],
  ['(qnames.unrank 17 1 (list 1 [10000]))','bad_bi'],
  ['(qnames.rank 17 [1 1])','duplicate'],
  ['(qnames.rank 17 [0])','id0'],
  ['(qnames.rank 17 [18])','id_over'],
  ['(qnames.rank 17 [1.5])','id_fraction'],
  ['(qnames.rank 17 [])','empty'],
  ['(qnames.rank 17 "bad)','word']
 ];
 for(const [expr,tag] of bad)lines.push(`(qn.bad ${expr} [${tag}])`);
 const cases=valid+bad.length, checks=valid*3+bad.length;
 lines.push(`if :QN.FAIL <> 0 [print [NAMES_QA_FALIIS] stop]
if :QN.CASES <> ${cases} [print [NAMES_QA_COUNT_FALIIS] stop]
if :QN.CHECKS <> ${checks} [print [NAMES_QA_CHECKS_FALIIS] stop]
print sentence [NAMES_QA_CASES_PASIS] :QN.CASES
print sentence [NAMES_QA_CHECKS_PASIS] :QN.CHECKS
print [NAMES_QA_PASIS]
`);
 return {fixture:lines.join("\n"),enumerated,valid,invalid:bad.length,cases,checks};
}
const h=makeFixture();
if(process.argv.length!==3) throw Error('Usage: node oracle.mjs OUTPUT');
writeFileSync(process.argv[2],h.fixture);
console.log(JSON.stringify({...h,fixture:undefined}));
