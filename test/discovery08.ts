import {
  bootstrapMonster, createMonsterContext, LegacyPermutationUnrankAdapter,
  Discovery08PermutationHandler, discoverLegacyPermutation,
  MonsterStageError, MonsterValidationError,
  patch01Save, patch02DayTags, patch03Distance, patch04Stones,
  patch05HiddenDrops, patch06Prior, patch07Grind, calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, SAVE, STONES, workCounts,
  bowlOrderFromDrop, permutationUnrank1
} from "./normativeOracle.ts";

function check(ok:boolean,why:string):void { if(!ok)throw new Error(why); }
function rejects(fn:()=>unknown,cls:typeof MonsterStageError|typeof MonsterValidationError):boolean {
  try {fn();} catch(e) {return e instanceof cls;} return false;
}
const adapter=new LegacyPermutationUnrankAdapter();
const handler=new Discovery08PermutationHandler();
const items=[1,2,3,4,5,6];

// मूळ zero-based helper त्याच्या परिभाषित domain मध्ये अचूक आहे.
for(const zero of [0n,1n,2n,5n,119n,120n,359n,718n,719n]) {
  const got=adapter.oldPermutationUnrank0(zero);
  const oracle=permutationUnrank1(zero+1n,items);
  check(Object.isFrozen(got) && got.length===6 &&
    got.every((v,i)=>v===oracle[i]),
    "मूळ helper 0..719 मध्ये अचूक zero-based unrank असावा");
}
check(adapter.oldPermutationUnrank0(0n).join(",")==="1,2,3,4,5,6" &&
  adapter.oldPermutationUnrank0(719n).join(",")==="6,5,4,3,2,1",
  "lexicographic पहिली व शेवटची निश्चित permutations");

const witnesses: readonly bigint[]=[
  -1n,0n,1n,2n,6n,719n,720n,721n,1440n,M
];
let mismatches=0,matches=0,rejections=0,accepted=0;
const contexts=new Set<object>();
for(const drop of witnesses) {
  const observed=discoverLegacyPermutation(F,F,drop);
  const expected=bowlOrderFromDrop(drop);
  const legal=drop>=0n && drop<720n;
  check(observed.dropValue===drop && observed.legacyRank0===drop &&
    observed.legacyAccepted===legal,"जुन्या caller ने drop थेट rank0 मानला");
  check(Object.isFrozen(observed) && !contexts.has(observed.context),"frozen स्वतंत्र निरीक्षण");
  contexts.add(observed.context);
  check(observed.context.phase==="READY" && observed.context.status==="DISCOVERY_08_RECORDED" &&
    observed.context.branchTrace.join(",")===[
      "BOOTSTRAP_VALIDATE","DISCOVERY_08_DROP_AS_RAW_ZERO_BASED_RANK",
      legal?"DISCOVERY_08_LEGACY_RANK_ACCEPTED":"DISCOVERY_08_LEGACY_RANK_REJECTED"
    ].join(","),"branch trace व status");
  check(observed.context.metrics.get("bootstrap.calls")===1n &&
    observed.context.metrics.get("discovery08.calls")===1n &&
    (observed.context.metrics.get("discovery08.legacy_accepted")??0n)===BigInt(legal?1:0) &&
    (observed.context.metrics.get("discovery08.legacy_rejections")??0n)===BigInt(legal?0:1),
    "मोजणी अचूक");

  if(legal) {
    accepted++;
    check(observed.legacyOrder!==null && observed.legacyRejection===null &&
      observed.legacyOrder===null?false:true,"legacy result आवश्यक");
    check(observed.legacyOrder!==null && Object.isFrozen(observed.legacyOrder) &&
      observed.legacyOrder.every((v,i)=>v===adapter.oldPermutationUnrank0(drop)[i]),
      "मूळ helper चा actual zero-based क्रमचय");
    if(observed.legacyOrder.join(",")===expected.join(","))matches++;else mismatches++;
  }else {
    rejections++;
    check(observed.legacyOrder===null && observed.legacyRejection==="OUT_OF_RANGE",
      "बाहेरील rank असल्यास जाणीवपूर्वक legacy rejection");
    mismatches++;
  }
}
check(mismatches===10 && matches===0 && rejections===5 && accepted===5,
  "दहा स्पष्ट ऐतिहासिक साक्षी: पाच चुकीचे, पाच rank नाकारले");

// रिअल legacy helper invocation instrument करून सिद्ध करा.
const previous=LegacyPermutationUnrankAdapter.prototype.oldPermutationUnrank0;
const seen:bigint[]=[];
try {
  LegacyPermutationUnrankAdapter.prototype.oldPermutationUnrank0=function(rank0) {
    seen.push(rank0);
    return previous.call(this,rank0);
  };
  discoverLegacyPermutation(F,F,1n);
  discoverLegacyPermutation(F,F,720n);
  check(seen.length===2 && seen[0]===1n && seen[1]===720n,
    "खरी जुनी call, normalization न करता");
}finally{LegacyPermutationUnrankAdapter.prototype.oldPermutationUnrank0=previous;}

const unready=createMonsterContext(F,F);
check(rejects(()=>handler.run(unready,1n),MonsterStageError) &&
  unready.status==="NEW" && unready.metrics.size===0 &&
  unready.branchTrace.length===0,"अवैध context अपरिवर्तित");
const ready=bootstrapMonster(F,F);
for(const bad of [1,1.5,"1",null,undefined] as unknown[]) {
  check(rejects(()=>handler.run(ready,bad as bigint),MonsterValidationError),
    "non-bigint drop नाकारावा");
  check(rejects(()=>adapter.oldPermutationUnrank0(bad as bigint),MonsterValidationError),
    "legacy helper bigint चाच असावा");
}
for(const bad of [-1n,720n,721n,M]) {
  check(rejects(()=>adapter.oldPermutationUnrank0(bad),MonsterValidationError),
    "helper च्या 0..719 सीमा");
}
check(rejects(()=>handler.run({...ready,targetDay:1 as unknown as bigint},1n),
  MonsterValidationError),"context day validation");
check(ready.status==="VALIDATED" && ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE" &&
  ready.metrics.size===1,"preflight नंतर context बदलू नये");
handler.run(ready,1n);
check(rejects(()=>handler.run(ready,2n),MonsterStageError),
  "context पुन्हा वापरू नये");

const first=discoverLegacyPermutation(F,F,1n),second=discoverLegacyPermutation(F,F,1n);
first.context.logs.push("फक्त पहिल्यापुरते");
first.context.metrics.set("private",99n);
check(first.context!==second.context && first.legacyOrder!==second.legacyOrder &&
  second.context.logs.length===0 && !second.context.metrics.has("private"),
  "per-call memory ownership");

check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((v,i)=>v===STONES[2]![i]),"PATCH 04");
const canonical=[11n,13n,17n,19n,23n,29n,31n] as const;
const hidden=patch05HiddenDrops(F,F,canonical);
check(hidden.correctedReads.every((v,i)=>v===canonical[i]),"PATCH 05");
check(patch06Prior(F,F,[],hidden.backwardStored,1,7).correctedValue===31n,"PATCH 06");
check(patch07Grind(F,F,1,17n,29n,43n,71n,[101n,103n,107n,109n,113n]).correctedValue>=1n,"PATCH 07");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 सीमा");

console.log(`STAGE_16_DISCOVERY_08_GUARDS_PASS mismatches=${mismatches} matches=${matches} accepted=${accepted} rejected=${rejections} witnesses=${witnesses.length}`);
