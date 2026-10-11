import {
  bootstrapMonster, createMonsterContext, LegacyPermutationUnrankAdapter,
  Patch08PermutationHandler, patch08Permutation, discoverLegacyPermutation,
  MonsterStageError, MonsterValidationError,
  patch01Save, patch02DayTags, patch03Distance, patch04Stones,
  patch05HiddenDrops, patch06Prior, patch07Grind, calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, SAVE, STONES, workCounts,
  bowlOrderFromDrop, regularMod, permutationUnrank1
} from "./normativeOracle.ts";

function check(ok:boolean, msg:string):void {if(!ok)throw Error(msg);}
function rejects(f:()=>unknown, cls:typeof MonsterStageError|typeof MonsterValidationError):boolean{
  try{f();}catch(e){return e instanceof cls;}return false;
}

const handler=new Patch08PermutationHandler();
const old=new LegacyPermutationUnrankAdapter();
const drops=[-720n,-1n,0n,1n,2n,6n,119n,120n,359n,718n,719n,720n,721n,1439n,1440n,1441n,M] as const;
const seenContexts=new Set<object>();
let cases=0,mismatches=0,historicallyRejected=0,historicallyShifted=0;
for(const drop of drops) {
  const obs=patch08Permutation(F,F,drop);
  const expected=bowlOrderFromDrop(drop);
  const expectedOne=regularMod(drop-1n,720n)+1n;
  const oldDiagnostic=discoverLegacyPermutation(F,F,drop);
  cases++;
  if(obs.order.join(",")!==expected.join(","))mismatches++;
  check(obs.dropValue===drop && obs.oneBased===expectedOne &&
    obs.legacyRank0===obs.oneBased-1n && obs.legacyRank0>=0n && obs.legacyRank0<720n,
    "oneBased व legacyRank0 हे स्पष्ट स्वतंत्र चरण");
  check(obs.oneBased>=1n && obs.oneBased<=720n &&
    obs.order.length===6 && new Set(obs.order).size===6 &&
    obs.order.every(v=>v>=1&&v<=6) && Object.isFrozen(obs.order) &&
    Object.isFrozen(obs),"सहा वाट्यांचा immutable क्रम");
  check(obs.order.every((v,j)=>v===old.oldPermutationUnrank0(obs.legacyRank0)[j]),
    "जुना 0-based helper वास्तविक परिणाम");
  check(obs.order.every((v,j)=>v===permutationUnrank1(obs.oneBased,[1,2,3,4,5,6])[j]),
    "नियमाधारित zero आणि one based रूपांतरण");
  check(!seenContexts.has(obs.context),"प्रत्येक निरीक्षण स्वतंत्र");
  seenContexts.add(obs.context);
  check(obs.context.status==="PATCH_08_APPLIED" && obs.context.phase==="READY" &&
    obs.context.branchTrace.join(",")===[
      "BOOTSTRAP_VALIDATE","PATCH_08_ONE_BASED_MOD_720",
      "PATCH_08_SUBTRACT_ONE_FOR_LEGACY","PATCH_08_REAL_OLD_PERMUTATION_UNRANK0"
    ].join(","),"ऐतिहासिक तीन चरण branch trace");
  check(obs.context.metrics.get("bootstrap.calls")===1n &&
    obs.context.metrics.get("patch08.one_based_normalizations")===1n &&
    obs.context.metrics.get("patch08.rank0_conversions")===1n &&
    obs.context.metrics.get("patch08.legacy_calls")===1n &&
    obs.context.metrics.get("patch08.calls")===1n,"ऐतिहासिक तीन चरण metrics");

  if(oldDiagnostic.legacyAccepted) {
    historicallyShifted++;
    check(!obs.rawLegacyWouldReject &&
      oldDiagnostic.legacyOrder!==null &&
      oldDiagnostic.legacyOrder.join(",")!==obs.order.join(",") &&
      obs.context.metrics.get("patch08.raw_legacy_shift_fixed")===1n,
      "accepted पण चुकीची जुनी permutation");
  } else {
    historicallyRejected++;
    check(obs.rawLegacyWouldReject && oldDiagnostic.legacyOrder===null &&
      obs.context.metrics.get("patch08.raw_legacy_rejections_avoided")===1n,
      "जुन्या नकाराऐवजी वैध rank");
  }
}
check(cases===17 && mismatches===0 && historicallyShifted===9 &&
  historicallyRejected===8,"17 boundary cases मधील शून्य दुरुस्ती फरक");

// जुना helper थेट योग्य 0-based rank सह invoke होतो; shortcut/static order नाही.
const original=LegacyPermutationUnrankAdapter.prototype.oldPermutationUnrank0;
const observedRanks:bigint[]=[];
try{
  LegacyPermutationUnrankAdapter.prototype.oldPermutationUnrank0=function(r) {
    observedRanks.push(r);return original.call(this,r);
  };
  for(const d of [-1n,0n,1n,719n,720n,721n,1440n])
    patch08Permutation(F,F,d);
  const expectedRanks=[718n,719n,0n,718n,719n,0n,719n];
  check(observedRanks.length===expectedRanks.length &&
    observedRanks.every((v,j)=>v===expectedRanks[j]),
    "मूळ method खरे कॉल होते, तीन पायऱ्यांची मान्यता");
} finally {LegacyPermutationUnrankAdapter.prototype.oldPermutationUnrank0=original;}

const unborn=createMonsterContext(F,F);
check(rejects(()=>handler.run(unborn,1n),MonsterStageError) &&
  unborn.status==="NEW" && unborn.metrics.size===0 && !unborn.branchTrace.length,
  "unready context mutation होऊ नये");
const ready=bootstrapMonster(F,F);
for(const bad of [0,1,1.5,"1",null,undefined,NaN] as unknown[]) {
  check(rejects(()=>handler.run(ready,bad as bigint),MonsterValidationError),
    "non-bigint drop नाकारावा");
}
check(rejects(()=>handler.run({...ready,calculationDay:0 as unknown as bigint},1n),
    MonsterValidationError),"दिवस संदर्भाची validation");
check(ready.status==="VALIDATED" && ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE" &&
  ready.metrics.size===1,"preflight failure ने state बदलू नये");
handler.run(ready,1n);
check(rejects(()=>handler.run(ready,2n),MonsterStageError),
  "दुबार संदर्भ वापर होऊ नये");

const left=patch08Permutation(F,F,-701n);
const right=patch08Permutation(F,F,-701n);
left.context.logs.push("डावा");
left.context.metrics.set("private",42n);
check(left.order!==right.order && left.context!==right.context &&
  !right.context.logs.length && !right.context.metrics.has("private") &&
  left.order.join(",")===right.order.join(","),"मालकी व isolation");

check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((v,j)=>v===STONES[2]![j]),"PATCH 04");
const hidden=patch05HiddenDrops(F,F,[11n,13n,17n,19n,23n,29n,31n]);
check(hidden.correctedReads[0]===11n && hidden.correctedReads[6]===31n,"PATCH 05");
check(patch06Prior(F,F,[],hidden.backwardStored,1,7).correctedValue===31n,"PATCH 06");
check(patch07Grind(F,F,1,17n,29n,43n,71n,[101n,103n,107n,109n,113n]).correctedValue>=1n,"PATCH 07");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 सीमा");
console.log(`STAGE_17_PATCH_08_GUARDS_PASS cases=${cases} shifted=${historicallyShifted} rejected=${historicallyRejected} mismatches=${mismatches}`);
