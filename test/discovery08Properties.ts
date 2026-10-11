import {
  LegacyPermutationUnrankAdapter, discoverLegacyPermutation
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, bowlOrderFromDrop, permutationUnrank1
} from "./normativeOracle.ts";
function check(ok:boolean,why:string):void {if(!ok)throw Error(why);}
const adapter=new LegacyPermutationUnrankAdapter();
const items=[1,2,3,4,5,6];
const unique=new Set<string>();
let direct=0;
for(let rank0=0n;rank0<720n;rank0++){
  const got=adapter.oldPermutationUnrank0(rank0);
  const expected=permutationUnrank1(rank0+1n,items);
  check(got.length===6 && got.every((v,j)=>v===expected[j]) &&
    new Set(got).size===6 && got.every(v=>v>=1&&v<=6),
    "0..719 या जुना helper पूर्ण 720 क्रमचयांमध्ये स्वतः बरोबर");
  unique.add(got.join(","));
  direct++;
}
check(direct===720 && unique.size===720,"सर्व 6! lexicographic permutations unique");

let cases=0,mismatches=0,inRange=0,rejected=0;
const contexts=new Set<object>();
function checkDrop(drop:bigint,c=F,t=F):void{
  const actual=discoverLegacyPermutation(c,t,drop);
  const expected=bowlOrderFromDrop(drop);
  cases++;
  check(!contexts.has(actual.context),"नवे निरीक्षण प्रत्येकवेळी");
  contexts.add(actual.context);
  check(actual.legacyRank0===drop,"जुना caller raw drop वापरतो");
  if(drop>=0n&&drop<=719n){
    inRange++;
    check(actual.legacyAccepted && actual.legacyOrder!==null &&
      actual.legacyRejection===null && Object.isFrozen(actual.legacyOrder),
      "legacy helper ने वैध rank स्वीकारला पाहिजे");
    check(actual.legacyOrder.every((v,j)=>v===adapter.oldPermutationUnrank0(drop)[j]),
      "खरा oldPermutationUnrank0 helper return");
    if(actual.legacyOrder.join(",")!==expected.join(","))mismatches++;
  }else{
    rejected++;
    check(!actual.legacyAccepted && actual.legacyOrder===null &&
      actual.legacyRejection==="OUT_OF_RANGE","अयोग्य rank स्पष्ट नाकारावा");
    mismatches++;
  }
}
for(let drop=0n;drop<720n;drop++)checkDrop(drop);
for(let drop=1n;drop<=1440n;drop++)checkDrop(drop,F-31n,F+17n);
for(let drop=-720n;drop<0n;drop++)checkDrop(drop,F+1n,F-1n);
check(cases===2880 && mismatches===2880 && inRange===1439 &&
  rejected===1441,"0..719, 1..1440, -720..-1: 2880 अपेक्षित divergence");

const huge=(1n<<8192n)+193n;
const hugeDrops=[huge,huge+M,-huge,-huge-1n,huge*huge,-huge*huge,1n<<16384n,-(1n<<16384n)];
let giantCases=0;
for(const drop of hugeDrops){
  const obs=discoverLegacyPermutation(F-huge,F+huge,drop);
  check(obs.legacyRank0===drop && obs.legacyOrder===null &&
    obs.legacyRejection==="OUT_OF_RANGE","giant bigint चे रूपांतर न होता rejection");
  const reference=bowlOrderFromDrop(drop);
  check(reference.length===6 && new Set(reference).size===6,
    "normative reference ला giant signed drop समर्थ");
  giantCases++;
}
check(giantCases===8,"महाकाय signed rank inputs");

const prev=discoverLegacyPermutation(F,F,1n),next=discoverLegacyPermutation(F,F,1n);
prev.context.metrics.set("private",13n);
prev.context.warnings.push("वैयक्तिक");
check(!next.context.metrics.has("private") && !next.context.warnings.length &&
  prev.context!==next.context,"दोन contexts स्वतंत्र");

console.log(`STAGE_16_DISCOVERY_08_PROPERTIES_PASS direct=${direct} unique=${unique.size} cases=${cases} mismatches=${mismatches} accepted=${inRange} rejected=${rejected} giant=${giantCases}`);
