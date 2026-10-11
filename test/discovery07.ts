import {
  bootstrapMonster, createMonsterContext, LegacyGrindTableAdapter,
  LEGACY_GRIND_TABLE, Discovery07GrindHandler, discoverLegacyGrind,
  MonsterStageError, MonsterValidationError, patch06Prior, patch05HiddenDrops,
  patch04Stones, patch03Distance, patch02DayTags, patch01Save, calendarDateSpaghetti
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M, SAVE, STONES, workCounts } from "./normativeOracle.ts";
import { NORMATIVE_GRIND_ROWS, normativeGrindStep } from "./discovery07Fixtures.ts";

function check(ok:boolean,why:string):void { if(!ok)throw new Error(why); }
function rejects(fn:()=>unknown, cls:typeof MonsterStageError|typeof MonsterValidationError):boolean {
  try{fn()}catch(err){return err instanceof cls}return false;
}
const stone=Object.freeze([101n,103n,107n,109n,113n]);
const adapter=new LegacyGrindTableAdapter();
const contexts=new Set<object>();
let mismatches=0,matches=0,missing=0,shifted=0;
check(LEGACY_GRIND_TABLE.length===11 && NORMATIVE_GRIND_ROWS.length===11,
  "दोन्ही स्वतंत्र 11-अनुक्रम; अजून sentinel नाही");
check(Object.isFrozen(LEGACY_GRIND_TABLE) &&
  LEGACY_GRIND_TABLE.every(Object.isFrozen),"जुनी टेबल अपरिवर्तनीय हवी");

for(let g=1;g<=11;g++) {
  const actual=discoverLegacyGrind(F,F,g,17n,29n,43n,71n,stone);
  const expected=normativeGrindStep(g,17n,29n,43n,71n,stone);
  const expectedRow=NORMATIVE_GRIND_ROWS[g-1]!;
  check(!contexts.has(actual.context),"प्रत्येक आवाहन स्वतंत्र");
  contexts.add(actual.context);
  check(actual.grind===g && actual.legacyTableIndex===g &&
    actual.inputX===17n && actual.prior1===29n && actual.prior3===43n &&
    actual.prior7===71n,"input/legacy index नोंद");
  check(actual.context.phase==="READY" && actual.context.status==="DISCOVERY_07_RECORDED",
    "इतिहास context lifecycle");
  check(Object.isFrozen(actual) && Object.isFrozen(actual.inputStone) &&
    actual.inputStone!==stone,"input snapshot frozen असावा");
  check(actual.context.branchTrace.join(",") === [
    "BOOTSTRAP_VALIDATE","DISCOVERY_07_LEGACY_GRIND_INDEX_G",
    g===11?"DISCOVERY_07_MISSING_GRIND_11":"DISCOVERY_07_SHIFTED_GRIND_ROW"
  ].join(","),"प्रत्यक्ष चुकीची branch");
  check(actual.context.metrics.get("bootstrap.calls")===1n &&
    actual.context.metrics.get("discovery07.calls")===1n &&
    (actual.context.metrics.get("discovery07.missing_rows")??0n)===BigInt(g===11?1:0) &&
    (actual.context.metrics.get("discovery07.shifted_rows")??0n)===BigInt(g===11?0:1),
    "दोषाचे मापन अचूक असावे");
  const oldRow=adapter.legacyRow(g);
  if(g<11) {
    shifted++;
    check(actual.legacyRow===oldRow && oldRow===LEGACY_GRIND_TABLE[g] &&
      oldRow!==expectedRow &&
      oldRow!.every((item,j)=>item===NORMATIVE_GRIND_ROWS[g]![j]),
      "नियमाधारित g ऐवजी g+1 च्या टेबल ओळीवर जुनी call");
    check(typeof actual.legacyValue==="bigint" && actual.rowPresent,
      "पहिल्या दहा grind ला चुकीची numeric किंमत मिळाली पाहिजे");
  } else {
    missing++;
    check(oldRow===undefined && actual.legacyRow===undefined &&
      actual.legacyValue===undefined && !actual.rowPresent,
      "अकराव्या grind साठी टेबल मर्यादेपलीकडे");
  }
  if(actual.legacyValue===expected)matches++;else mismatches++;
}
check(mismatches===11 && matches===0 && missing===1 && shifted===10,
  "अकराही ऐतिहासिक साक्षींमध्ये फरक; शेवटची गायब");

// खरे legacy indexed table वाचले जाते याची instrumentation साक्ष.
const original=LegacyGrindTableAdapter.prototype.legacyRow;
let realCalls=0;
try {
  LegacyGrindTableAdapter.prototype.legacyRow=function(grind) {
    realCalls++;
    return original.call(this,grind);
  };
  discoverLegacyGrind(F,F,1,17n,29n,43n,71n,stone);
  discoverLegacyGrind(F,F,11,17n,29n,43n,71n,stone);
  check(realCalls===2,"जुन्या helper चे खरे invocation आवश्यक आहे");
} finally {
  LegacyGrindTableAdapter.prototype.legacyRow=original;
}

const handler=new Discovery07GrindHandler();
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,1,17n,29n,43n,71n,stone),MonsterStageError) &&
  raw.branchTrace.length===0 && raw.metrics.size===0 && raw.status==="NEW",
  "न पडताळलेला context बदलू नये");
const ready=bootstrapMonster(F,F);
for(const bad of [0,12,-1,1.5,NaN,Infinity,"1" as unknown as number]) {
  check(rejects(()=>handler.run(ready,bad,17n,29n,43n,71n,stone),MonsterValidationError) &&
    rejects(()=>adapter.legacyRow(bad),MonsterValidationError),
    "अवैध grind नाकारली पाहिजे");
}
check(rejects(()=>handler.run(ready,1,17 as unknown as bigint,29n,43n,71n,stone),
  MonsterValidationError),"अवैध x नाकारावा");
check(rejects(()=>handler.run(ready,1,17n,29n,43n,71n,
  Object.assign(new Array<bigint>(5),{0:1n,1:2n,3:4n,4:5n})),
  MonsterValidationError),"sparse stone नाकारावा");
check(rejects(()=>handler.run(ready,1,17n,29n,43n,71n,[1n,2n]),
  MonsterValidationError),"अपूर्ण stone नाकारावा");
check(rejects(()=>handler.run({...ready,calculationDay:null as unknown as bigint},
  1,17n,29n,43n,71n,stone),MonsterValidationError),"अवैध context day नाकारावा");
check(ready.status==="VALIDATED" && ready.metrics.size===1 &&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE","preflight अपयशाने context बदलू नये");
handler.run(ready,1,17n,29n,43n,71n,stone);
check(rejects(()=>handler.run(ready,1,17n,29n,43n,71n,stone),MonsterStageError),
  "संदर्भाचा दुसरा वापर नाकारावा");

const a=discoverLegacyGrind(F,F,1,17n,29n,43n,71n,stone);
const b=discoverLegacyGrind(F,F,1,17n,29n,43n,71n,stone);
a.context.logs.push("पहिल्यापुरते");
a.context.metrics.set("private",31n);
check(a.context!==b.context && !b.context.logs.length &&
  !b.context.metrics.has("private") && a.inputStone!==b.inputStone,
  "context आणि snapshots वेगळे");

// आधीचे टप्पे व अंतिम एकत्रीकरण सीमा बदललेली नाहीत.
check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
check(patch02DayTags(F,F+1n).target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(patch04Stones(F,F,2n,STONES[1]!).correctedStone.every((x,j)=>x===STONES[2]![j]),"PATCH 04");
const canonical=Object.freeze([11n,13n,17n,19n,23n,29n,31n]);
const patchedHidden=patch05HiddenDrops(F,F,canonical);
check(patchedHidden.correctedReads.every((x,j)=>x===canonical[j]),"PATCH 05");
check(patch06Prior(F,F,[undefined,19n],patchedHidden.backwardStored,1,7).correctedValue===31n,
  "PATCH 06");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 अजून उपलब्ध नाही");
console.log(`STAGE_14_DISCOVERY_07_GUARDS_PASS mismatches=${mismatches} matches=${matches} missing=${missing} shifted=${shifted}`);
