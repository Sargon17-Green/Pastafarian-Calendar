import {ScalableLegalWeavingUnrank,ScalableLegalWeavingCounter,
 MonsterValidationError,Patch23FullHandler,Discovery23FullHandler,
 Patch22FullHandler,Discovery22FullHandler,Patch21CutletHandler,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 patch23MonthLengths} from "../src/index.ts";
import {weavingFamily} from "./normativeOracle.ts";
import {assert,buildStage41CompatibleLegacyFixture} from "./discovery21Fixtures.ts";
let rows=0,families=0;
for(const ls of [[4n,4n,4n],[4n,4n,5n],[4n,5n,4n],[5n,4n,4n]]){
 const fast=new ScalableLegalWeavingUnrank(ls),ref=weavingFamily(ls);
 const N=ref.count();
 assert(fast.count()===N&&N===new ScalableLegalWeavingCounter(ls).count(),
  "small counts vs two independent oracles");
 for(let i=1n;i<=N;i++){
  assert(fast.itemAt1(i).join(",")===ref.unrank1(i).join(","),
   "exhaustive legal lex rank against independent oracle");
  rows++;
 }
 families++;
}
const f=buildStage41CompatibleLegacyFixture();
const mk=()=>new Patch23FullHandler(new Discovery23FullHandler(
 new Patch22FullHandler(new Discovery22FullHandler(new Patch21CutletHandler(
 new Discovery21LegacyCutletHandler(new Patch20StructureSauceHandler(
 new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())))))));
const full=patch23MonthLengths(mk(),f.request);
const ls=full.corrected.correctedLengths;
const fast=new ScalableLegalWeavingUnrank(ls),N=fast.count();
assert(ls.length===44&&ls.reduce((a,b)=>a+b,0n)===5349n&&
 N===new ScalableLegalWeavingCounter(ls).count(),
 "real 5349/44 independent exact count");
let giant=0;
for(const rank of [1n,(N+1n)/2n,N]){
 const word=fast.itemAt1(rank),seen=Array<number>(ls.length).fill(0);
 const first:number[]=[],last=Array<number>(ls.length).fill(-1);
 for(let i=0;i<word.length;i++){
  const j=word[i]!;
  if(seen[j-1]===0)first.push(j);
  seen[j-1]!++;last[j-1]=i;
 }
 const ordered=Array.from({length:ls.length},(_,i)=>i+1);
 const closed=[...ordered].sort((a,b)=>last[a-1]!-last[b-1]!);
 assert(word.length===5349&&seen.every((v,i)=>v===Number(ls[i]))&&
  first.join(",")===ordered.join(",")&&
  closed.join(",")===ordered.join(","),
  "real giant ranks obey all normative constraints");
 giant++;
}
let bad=0;
for(const k of [0n,N+1n]){
 try{fast.itemAt1(k);}catch(e){if(e instanceof MonsterValidationError)bad++;}
}
const st=fast.statistics();
assert(bad===2&&st.distributionKinds<=44&&
 st.distributionCells<=44*5350&&st.cachedFactors<=12000,
 "giant range limits and bounded suffix memory");
console.log("STAGE_49_SCALABLE_UNRANK_PASS"+
 " exhaustiveSmallLex="+rows+" smallFamilies="+families+
 " realYearDays=5349 realMonths=44 giantCountBits="+N.toString(2).length+
 " giantLexRanks="+giant+" distributions="+st.distributionKinds+
 " cells="+st.distributionCells+" transitions="+st.transitions+
 " suffixQueries="+st.suffixQueries+" fullNativeHandlerPending=1");
