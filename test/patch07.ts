import {
  bootstrapMonster, createMonsterContext, LEGACY_GRIND_TABLE,
  GRIND_TABLE_WITH_SENTINEL, GRIND_SENTINEL, LegacyGrindTableAdapter,
  Patch07GrindHandler, patch07Grind, discoverLegacyGrind,
  MonsterValidationError, MonsterStageError,
  patch01Save, patch02DayTags, patch03Distance, patch04Stones,
  patch05HiddenDrops, patch06Prior, calendarDateSpaghetti
} from "../src/index.ts";
import { FOUNDATION_DAY as F, STONES, M, SAVE, workCounts } from "./normativeOracle.ts";
import { NORMATIVE_GRIND_ROWS, normativeGrindStep } from "./discovery07Fixtures.ts";

function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
function rejects(f:()=>unknown,cls:typeof MonsterValidationError|typeof MonsterStageError):boolean{
  try{f()}catch(e){return e instanceof cls}return false;
}
const stone=Object.freeze([101n,103n,107n,109n,113n]);
const handler=new Patch07GrindHandler();
check(LEGACY_GRIND_TABLE.length===11 && GRIND_TABLE_WITH_SENTINEL.length===12,
  "जुनी table 11 व sentinel table 12 असलीच पाहिजे");
check(GRIND_TABLE_WITH_SENTINEL[0]===GRIND_SENTINEL &&
  Object.isFrozen(GRIND_SENTINEL) && Object.isFrozen(GRIND_TABLE_WITH_SENTINEL) &&
  GRIND_SENTINEL[0]===0n && GRIND_SENTINEL[1]===0n &&
  GRIND_SENTINEL[2]===0n && GRIND_SENTINEL[3]===0n &&
  GRIND_SENTINEL[4]==="NONE","index 0 sentinel अचूक व कायम");
for(let g=1;g<=11;g++) {
  check(GRIND_TABLE_WITH_SENTINEL[g]===LEGACY_GRIND_TABLE[g-1],
    "पूर्वीच्या 11 ओळी क्रम न बदलता index 1..11 वर हव्यात");
  check(GRIND_TABLE_WITH_SENTINEL[g]!.every((v,j)=>v===NORMATIVE_GRIND_ROWS[g-1]![j]),
    "ग्राइंडची खऱ्या नियमाधारित ओळीशी तुलना");
}
check(LEGACY_GRIND_TABLE[0]===GRIND_TABLE_WITH_SENTINEL[1] &&
  LEGACY_GRIND_TABLE[11]===undefined && GRIND_TABLE_WITH_SENTINEL[11]!==undefined,
  "ऐतिहासिक table किंवा index प्रत्यक्ष बदललेला नाही");

let rows=0,missingRepaired=0,shiftedRepaired=0,mismatches=0;
const contexts=new Set<object>();
for(let g=1;g<=11;g++){
  const obs=patch07Grind(F,F,g,17n,29n,43n,71n,stone);
  const expected=normativeGrindStep(g,17n,29n,43n,71n,stone);
  const old=discoverLegacyGrind(F,F,g,17n,29n,43n,71n,stone);
  rows++;
  if(obs.correctedValue!==expected)mismatches++;
  check(obs.grind===g && obs.indexUsed===g &&
    obs.actualRow===GRIND_TABLE_WITH_SENTINEL[g] &&
    obs.historicalRow===old.legacyRow &&
    obs.historicalRow===new LegacyGrindTableAdapter().legacyRow(g) &&
    obs.legacyReadOccurred,"legacy indexing चा प्रत्यक्ष पुरावा आणि नवीन ओळ");
  check(obs.correctedValue>=1n && obs.correctedValue<=M,
    "नियमाधारित SAVE सीमा");
  check(!contexts.has(obs.context),"प्रत्येक आवाहन स्वतंत्र context");
  contexts.add(obs.context);
  check(Object.isFrozen(obs) && Object.isFrozen(obs.inputStone) &&
    obs.inputStone!==stone && obs.inputStone.every((v,j)=>v===stone[j]),
    "frozen प्रत व immutable observation");
  check(obs.context.status==="PATCH_07_APPLIED" && obs.context.phase==="READY" &&
    obs.context.branchTrace.join(",")===[
      "BOOTSTRAP_VALIDATE","PATCH_07_REAL_LEGACY_ROW_READ",
      "PATCH_07_SENTINEL_INDEX_G",g===11?
        "PATCH_07_REPAIRED_MISSING_11":"PATCH_07_REPAIRED_SHIFTED_ROW"
    ].join(","),"status आणि शाखा मार्ग");
  check(obs.context.metrics.get("bootstrap.calls")===1n &&
    obs.context.metrics.get("patch07.calls")===1n &&
    obs.context.metrics.get("patch07.historical_reads")===1n &&
    (obs.context.metrics.get("patch07.missing_row_repairs")??0n)===BigInt(g===11?1:0) &&
    (obs.context.metrics.get("patch07.shifted_row_repairs")??0n)===BigInt(g===11?0:1),
    "historical shadow metrics");
  if(g===11){
    missingRepaired++;
    check(obs.historicalRowMissing && old.legacyValue===undefined,
      "अकरावी टेबल ओळ आता आढळते; जुनी मात्र गहाळच");
  }else {
    shiftedRepaired++;
    check(!obs.historicalRowMissing && old.legacyValue!==undefined &&
      old.legacyValue!==expected,"पहिल्या दहा जुन्या चुका अजून दिसल्या पाहिजेत");
  }
}
check(rows===11 && missingRepaired===1 && shiftedRepaired===10 && mismatches===0,
  "11 grind rows, 10 shifted, 1 missing: सर्व दुरुस्त");

// patched handler इतिहासातील खऱ्या legacy adapter ला call करतो, हे स्वतंत्र सिद्ध करा.
const original=LegacyGrindTableAdapter.prototype.legacyRow;
let legacyCalls=0;
try {
  LegacyGrindTableAdapter.prototype.legacyRow=function(g) {
    legacyCalls++;return original.call(this,g);
  };
  patch07Grind(F,F,1,17n,29n,43n,71n,stone);
  patch07Grind(F,F,11,17n,29n,43n,71n,stone);
  check(legacyCalls===2,"जुन्या method चे दोन खरे calls व्हावेत");
}finally{LegacyGrindTableAdapter.prototype.legacyRow=original;}

// context guard आणि type validation सर्व अंकांसाठी.
const invalidCtx=createMonsterContext(F,F);
check(rejects(()=>handler.run(invalidCtx,1,17n,29n,43n,71n,stone),MonsterStageError) &&
  invalidCtx.status==="NEW" && invalidCtx.branchTrace.length===0 &&
  invalidCtx.metrics.size===0,"unready context बदलू नये");
const ready=bootstrapMonster(F,F);
for(const g of [0,-1,12,1.5,NaN,Infinity,"1" as unknown as number]){
  check(rejects(()=>handler.run(ready,g,17n,29n,43n,71n,stone),MonsterValidationError) &&
    rejects(()=>handler.oneBasedRow(g),MonsterValidationError),
    "grind range/number validation");
}
for(const [x,p1,p3,p7] of [
  [17 as unknown as bigint,29n,43n,71n],
  [17n,29 as unknown as bigint,43n,71n],
  [17n,29n,43 as unknown as bigint,71n],
  [17n,29n,43n,71 as unknown as bigint]
] as const){
  check(rejects(()=>handler.run(ready,1,x,p1,p3,p7,stone),MonsterValidationError),
    "non-bigint history नाकारावी");
}
for(const malformed of [
  [],[1n,2n,3n,4n],[1n,2n,3n,4n,5n,6n],
  [1n,2n,3n,4n,undefined as unknown as bigint],
  [1n,2n,3n,4n,5 as unknown as bigint],
  Object.assign(new Array<bigint>(5),{0:1n,1:2n,3:4n,4:5n})
]) {
  check(rejects(()=>handler.run(ready,1,17n,29n,43n,71n,malformed),MonsterValidationError),
    "sparse किंवा चुकीचा stone");
}
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},1,17n,29n,43n,71n,stone),
  MonsterValidationError),"invalid context day");
check(ready.status==="VALIDATED" && ready.metrics.size===1 &&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","preflight अपयशाने context mutate होऊ नये");
handler.run(ready,1,17n,29n,43n,71n,stone);
check(rejects(()=>handler.run(ready,2,17n,29n,43n,71n,stone),MonsterStageError),
  "context reuse नाकारावा");

const input=[11n,13n,17n,19n,23n];
const left=patch07Grind(F,F,2,2n,3n,5n,7n,input);
const right=patch07Grind(F,F,2,2n,3n,5n,7n,input);
input[0]=101n;left.context.logs.push("पहिला");left.context.metrics.set("private",88n);
check(left.correctedValue===right.correctedValue &&
  left.inputStone[0]===11n && right.inputStone[0]===11n &&
  left.context!==right.context && left.inputStone!==right.inputStone &&
  !right.context.logs.length && !right.context.metrics.has("private"),
  "input snapshots आणि call isolation");

// सहा जुने PATCH व Stage 54 चा मुद्दाम बंद अंतिम मार्ग.
check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((v,j)=>v===STONES[2]![j]),"PATCH 04");
const canon=Object.freeze([11n,13n,17n,19n,23n,29n,31n]);
const hidden=patch05HiddenDrops(F,F,canon);
check(hidden.correctedReads.every((v,j)=>v===canon[j]),"PATCH 05");
check(patch06Prior(F,F,[undefined,23n],hidden.backwardStored,1,7).correctedValue===31n,"PATCH 06");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 route unavailable");
console.log(`STAGE_15_PATCH_07_GUARDS_PASS rows=${rows} shifted=${shiftedRepaired} missing=${missingRepaired} mismatches=${mismatches}`);
