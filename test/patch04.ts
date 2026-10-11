import {
  bootstrapMonster, calendarDateSpaghetti, createMonsterContext,
  discoverLegacyStoneMutation, LegacySequentialStoneAdapter, MonsterStageError,
  MonsterValidationError, patch01Save, patch02DayTags, patch03Distance,
  patch04Stones, Patch04StoneHandler
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M, SAVE, STONES, workCounts } from "./normativeOracle.ts";

function check(condition: boolean, message: string): void {
  if (!condition) throw new Error(message);
}
function rejects(work: () => unknown, kind: typeof MonsterStageError | typeof MonsterValidationError): boolean {
  try { work(); } catch (error) { return error instanceof kind; }
  return false;
}
function oldFormula(index: bigint, input: readonly bigint[]): readonly bigint[] {
  const [w,b,s,m,r] = input;
  return [
    SAVE(w!*w! + 3n*b! + index),
    SAVE(b!*b! + 5n*s! + w!),
    SAVE(s!*s! + 7n*m! + b!),
    SAVE(m!*m! + 11n*r! + s!),
    SAVE(r!*r! + 13n*w! + m!)
  ];
}

let cases=0, cells=0, mismatches=0, overwritten=0, legacyCalls=0, differing=0;
const contexts=new Set<object>();
const adapter=new LegacySequentialStoneAdapter();

function verify(index: bigint, input: readonly bigint[], c=F, t=F): readonly bigint[] {
  const original=[...input];
  const obs=patch04Stones(c,t,index,input);
  const normative=oldFormula(index,input);
  const legacyCopy=[...input] as [bigint,bigint,bigint,bigint,bigint];
  const sameAlias=adapter.mutateStonesWrong(index,legacyCopy,c,t);
  check(sameAlias===legacyCopy, "जुन्या mutation चा in-place पुरावा बदलला");
  check(obs.legacyCalledOnClone, "खरा जुना call झाला पाहिजे");
  check(!contexts.has(obs.context), "प्रत्येक आवाहनाची स्वतंत्र context आवश्यक");
  contexts.add(obs.context);
  check(Object.isFrozen(obs) && Object.isFrozen(obs.inputStone) &&
    Object.isFrozen(obs.legacyGarbage) && Object.isFrozen(obs.correctedStone),
    "सर्व निरीक्षणे frozen असावीत");
  check(obs.stoneIndex===index && obs.inputStone.length===5 &&
    obs.legacyGarbage.length===5 && obs.correctedStone.length===5, "पाच दगडांचा आकार");
  check(obs.context.phase==="READY" && obs.context.status==="PATCH_04_APPLIED",
    "संदर्भ जीवनचक्र चुकीचे");
  check(obs.context.branchTrace.join("|")===[
    "BOOTSTRAP_VALIDATE","PATCH_04_SNAPSHOT_OLD",
    "PATCH_04_REAL_LEGACY_ON_CLONE","PATCH_04_OVERWRITE_ALL_FROM_OLD"
  ].join("|"), "legacy call + snapshot trace क्रम चुकीचा");
  check(obs.context.metrics.get("bootstrap.calls")===1n &&
    obs.context.metrics.get("patch04.calls")===1n &&
    obs.context.metrics.get("patch04.legacy_invocations")===1n &&
    obs.context.metrics.get("patch04.cells_computed")===5n, "आवाहनाची मोजणी चुकीची");

  let replaced=0;
  for(let k=0;k<5;k++){
    cells++;
    check(input[k]===original[k] && obs.inputStone[k]===original[k],
      "मूळ दगडांचे mutable स्वामित्व तुटले");
    check(obs.legacyGarbage[k]===legacyCopy[k], "प्रमाणित जुने garbage वेगळे");
    if(obs.correctedStone[k]!==normative[k])mismatches++;
    check(obs.correctedStone[k]===normative[k], "नियमाधारित old snapshot सूत्राशी फरक");
    check(obs.correctedStone[k]!>=1n && obs.correctedStone[k]!<=M, "SAVE श्रेणी");
    if(obs.legacyGarbage[k]!==obs.correctedStone[k]) replaced++;
  }
  check(obs.overwrittenCells===replaced &&
    (obs.context.metrics.get("patch04.cells_changed_from_garbage")??0n)===BigInt(replaced),
    "garbage पासून वेगळे असणाऱ्या दगडांची मोजणी");
  cases++;legacyCalls++;overwritten+=replaced;
  if(replaced>0)differing++;
  return obs.correctedStone;
}

const first=STONES[1]!;
const originalFirst=[...first];
const fixedFirst=verify(2n,first);
check(fixedFirst.every((v,i)=>v===STONES[2]![i]), "पहिल्या पाच दगडांचे अचूक उत्तर");
check(fixedFirst.join(",")==="378,1073,2375,6195,10493", "पहिल्या दगडांची प्रकाशित साक्ष");
check(first.every((v,i)=>v===originalFirst[i]), "जुना oracle input बदलला");
const badFirst=discoverLegacyStoneMutation(F,F,2n,first);
check(badFirst.legacyStone.join(",")==="378,1434,3780,9932,25047", "जुना historical दोष कायम असावा");
const verifiedFirst=patch04Stones(F,F,2n,first);
check(verifiedFirst.overwrittenCells===4, "पहिल्या पाच दगडांत नेमके चार फरक हवेत");
check(verifiedFirst.legacyGarbage.join(",")===badFirst.legacyStone.join(","),
  "प्रत्यक्ष जुनी call वापरलेली असावी");

// सर्व 45 पायऱ्या, प्रत्येक पायरीवर बरोबर मागील दगडांपासून पुढील दगड.
let previous: readonly bigint[]=STONES[1]!;
for(let i=2;i<=46;i++){
  previous=verify(BigInt(i),previous);
  check(previous.every((v,k)=>v===STONES[i]![k]), "नियमाधारित 46 दगडांचा कालक्रम चुकीचा");
}

// मोठी परिमाणे, शून्य, ऋण मूल्ये आणि विविध कॅलेंडर दिवस.
const huge=(1n<<16384n)+239n;
const special=[
  [0n,0n,0n,0n,0n],
  [M,M,M,M,M],
  [M+1n,-M-1n,0n,1n,-1n],
  [huge,-huge,0n,M,-M],
  [-huge,huge,3n*M,-3n*M,huge+M],
  [17n,29n,43n,71n,101n]
] as const;
for(let i=0;i<special.length;i++)verify(BigInt(2+i),special[i]!,F-BigInt(i),F+BigInt(i));

let seed=0x6a09e667f3bcc909n;
const mask=(1n<<512n)-1n;
for(let run=0;run<1024;run++){
  const sample:bigint[]=[];
  for(let k=0;k<5;k++){
    seed=(seed*6364136223846793005n+1442695040888963407n)&mask;
    sample.push(seed-(1n<<511n));
  }
  verify(BigInt(2+(run%45)),sample,F+BigInt(run%17),F-BigInt(run%19));
}

// संदर्भाचे स्वतंत्र स्वामित्व आणि call ordering neutrality.
const a=patch04Stones(F-4n,F+3n,2n,first);
const b=patch04Stones(F-4n,F+3n,2n,first);
a.context.logs.push("पहिले");
a.context.warnings.push("फक्त पहिला");
a.context.metrics.set("private",17n);
check(b.context.logs.length===0 && b.context.warnings.length===0 &&
  !b.context.metrics.has("private"),"दोन आवाहनांत mutable स्थिती सांडते");
check(a.correctedStone.join(",")===b.correctedStone.join(",") &&
  a.legacyGarbage.join(",")===b.legacyGarbage.join(","),"आवाहन क्रमाचा फरक");

// validation आधी असावी; चुकलेल्या input ने context / stone बदलू नये.
const handler=new Patch04StoneHandler();
const raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,2n,first),MonsterStageError),"BOOTSTRAP अवस्थेला मज्जाव");
check(raw.branchTrace.length===0 && raw.metrics.size===0,"अवैध अवस्थेवर परिणाम नको");
const ready=bootstrapMonster(F,F);
check(rejects(()=>handler.run(ready,1n,first),MonsterValidationError),"अवैध क्रमांक");
check(rejects(()=>handler.run(ready,2n,[1n,2n]),MonsterValidationError),"अपूर्ण दगड");
check(rejects(()=>handler.run(ready,2n,[1n,2n,3n,4n,5 as unknown as bigint]),
  MonsterValidationError),"गैर-bigint दगड");
check(rejects(()=>handler.run({...ready,targetDay:"wrong" as unknown as bigint},2n,first),
  MonsterValidationError),"संदर्भातील अवैध दिवस");
check(ready.status==="VALIDATED" && ready.branchTrace.length===1 && ready.metrics.size===1,
  "चुकलेल्या input नंतर तयार संदर्भ बदलू नये");
handler.run(ready,2n,first);
check(rejects(()=>handler.run(ready,2n,first),MonsterStageError),"वापरलेल्या संदर्भाला मज्जाव");

// जुन्या तीन PATCH आणि अजून-अनुपलब्ध अंतिम दिनांक-मार्गावर दुष्परिणाम नको.
check(patch01Save(F,F,3n*M).savedValue===SAVE(3n*M),"PATCH 01");
const days=patch02DayTags(F,F+1n);
check(days.action.correctedTag===1n && days.target.correctedTag===3n,"PATCH 02");
check(patch03Distance(F-2n,F+2n).distance===workCounts(F-2n,F+2n).distance,"PATCH 03");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),"Stage 54 लवकर सुरू नये");
check(cases===1+45+special.length+1024 && cells===5*cases && legacyCalls===cases &&
  mismatches===0 && overwritten>0 && differing>0,"सर्व oracle आणि जुन्या call साक्षी");
console.log(`STAGE_09_PATCH_04_PASS cases=${cases} cells=${cells} legacyCalls=${legacyCalls} overwritten=${overwritten} mismatches=${mismatches}`);
