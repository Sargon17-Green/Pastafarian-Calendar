import {
  discoverLegacyHiddenStorage, LegacyBackwardHiddenAdapter, MonsterValidationError
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M } from "./normativeOracle.ts";

function check(ok:boolean, description:string):void {
  if(!ok)throw new Error(description);
}
const adapter = new LegacyBackwardHiddenAdapter();
let cases=0, slots=0, mismatches=0, matches=0, contexts=new Set<object>();

function verify(input: readonly bigint[], c=F, t=F):void {
  const prior=[...input];
  const observed=discoverLegacyHiddenStorage(c,t,input);
  check(!contexts.has(observed.context),"संदर्भ प्रत्येक प्रयोगासाठी नवीन हवा");
  contexts.add(observed.context);
  const duplicateStorage=adapter.storeBackward(input);
  check(duplicateStorage!==observed.backwardStored && Object.isFrozen(duplicateStorage),
    "साठवण प्रत्येक प्रयोगात नवीन आणि immutable हवी");
  check(duplicateStorage.every((v,j)=>v===observed.backwardStored[j]),"खरा उलटा क्रम हवा");
  for(let k=1;k<=7;k++){
    const normal=input[k-1]!;
    const historical=observed.legacyReads[k-1]!;
    check(input[k-1]===prior[k-1] && observed.sourceInCanonicalOrder[k-1]===normal,
      "input ने बदल स्वीकारू नयेत");
    check(historical===prior[7-k] &&
      adapter.oldHiddenAt(observed.backwardStored,k)===historical,
      "legacy accessor ने चुकीच्याच k-1 slot मध्ये पाहायला हवे");
    if(normal===historical)matches++;else mismatches++;
    slots++;
  }
  cases++;
}

verify([1n,2n,3n,4n,5n,6n,7n]);
verify([7n,6n,5n,4n,3n,2n,1n]);
verify([0n,1n,2n,3n,2n,1n,0n]); // सममित स्रोत: चुकीचे वाचन योगायोगाने योग्य.
verify([0n,0n,0n,0n,0n,0n,0n]);
verify([M,-M,0n,1n,2n,3n,-1n]);
const huge=(1n<<8192n)+191n;
verify([huge,-huge,0n,M,-M,3n*huge,-3n*huge],F-10n,F+10n);

const modulus=(1n<<512n)-1n;
let state=0x243f6a8885a308d3n;
for(let j=0;j<1024;j++){
  const input:bigint[]=[];
  for(let k=0;k<7;k++){
    state=(state*6364136223846793005n+1442695040888963407n)&modulus;
    input.push(state-(1n<<511n));
  }
  verify(input,F+BigInt(j%19),F-BigInt(j%23));
}

// 1024 जतन-क्रम प्रयोगांत फक्त मधला k=4 स्वतःशी जुळतो.
check(cases===1030 && slots===7210 && matches>=1030 && mismatches>0,
  "योग्य-चुकीची दोन्ही साक्षी आणि मोजणी आवश्यक आहेत");
check(contexts.size===cases, "सर्व आवाहनांचे संदर्भ स्वतंत्र असावेत");

// invalid float/undefined/NaN/Infinity index वा पोकळ array आधीच नाकारला पाहिजे.
const backward=adapter.storeBackward([1n,2n,3n,4n,5n,6n,7n]);
for(const k of [0,8,-1,1.5,NaN,Infinity]){
  let rejected=false;
  try{adapter.oldHiddenAt(backward,k)}catch(e){rejected=e instanceof MonsterValidationError}
  check(rejected,"बेकायदा legacy slot नाकारावा");
}
console.log(`STAGE_10_DISCOVERY_05_PROPERTIES_PASS cases=${cases} slots=${slots} mismatches=${mismatches} matches=${matches}`);
