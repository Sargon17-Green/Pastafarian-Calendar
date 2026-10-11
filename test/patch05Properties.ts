import {
  LegacyBackwardHiddenAdapter, Patch05HiddenHandler, patch05HiddenDrops
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M } from "./normativeOracle.ts";

function check(ok:boolean, message:string):void { if(!ok)throw Error(message); }
const adapter=new LegacyBackwardHiddenAdapter();
const patch=new Patch05HiddenHandler();
let cases=0, cells=0, legacyDifferences=0, equalities=0;
const contexts=new Set<object>();

function verify(values:readonly bigint[], c=F, t=F):void {
  const original=[...values];
  const observation=patch05HiddenDrops(c,t,values);
  check(!contexts.has(observation.context),"नवीन context आवश्यक");
  contexts.add(observation.context);
  const freshBackward=adapter.storeBackward(values);
  const transformed=[...values].reverse();
  let diffs=0;
  for(let k=1;k<=7;k++){
    const j=k-1;
    check(values[j]===original[j] && observation.sourceInCanonicalOrder[j]===original[j],
      "कॉलरच्या मूळ यादीत mutation होऊ नये");
    check(observation.backwardStored[j]===freshBackward[j] &&
      observation.backwardStored[j]===transformed[j],
      "उलटे historical storage अपरिवर्तित असावे");
    check(observation.legacyReads[j]===adapter.oldHiddenAt(observation.backwardStored,k),
      "जुना कर्ता खरा वापरलेला असावा");
    check(observation.correctedReads[j]===original[j] &&
      patch.correctedHiddenAt(observation.backwardStored,k)===original[j],
      "सूत्र 8-k नेच नियमाधारित थेंब मिळावा");
    check(observation.correctedSlotsOneBased[j]===8-k,
      "zero-based 7-k आणि one-based 8-k जुळावे");
    if(observation.correctedReads[j]===observation.legacyReads[j])equalities++;
    else {legacyDifferences++;diffs++;}
    cells++;
  }
  check(observation.mismatchesRepaired===diffs &&
    (observation.context.metrics.get("patch05.legacy_mismatches")??0n)===BigInt(diffs),
    "ऐतिहासिक फरक मापन");
  cases++;
}

verify([1n,2n,3n,4n,5n,6n,7n]);
verify([7n,6n,5n,4n,3n,2n,1n]);
verify([0n,1n,2n,3n,2n,1n,0n]); // palindrome: जुनी चूक दडलेली राहते.
verify([0n,0n,0n,0n,0n,0n,0n]);
verify([M,-M,0n,1n,2n,3n,-1n]);
const huge=(1n<<16384n)+193n;
verify([huge,-huge,0n,M,-M,3n*huge,-3n*huge],F-100n,F+100n);
verify([M+1n,-(M+1n),-(1n<<4096n),1n<<4096n,0n,huge,-huge]);

const modulus=(1n<<512n)-1n;
let state=0x6a09e667f3bcc909n;
for(let run=0;run<2048;run++){
  const values:bigint[]=[];
  for(let k=0;k<7;k++){
    state=(state*6364136223846793005n+1442695040888963407n)&modulus;
    values.push(state-(1n<<511n));
  }
  verify(values,F+BigInt(run%37),F-BigInt(run%41));
}
// प्रत्येक मूळ स्थानाचा एका unique value च्या प्रतिसादात वेगळा परिणाम असतो.
for(let position=0;position<7;position++){
  const unique=Array(7).fill(0n) as bigint[];
  unique[position]=BigInt(position+101);
  verify(unique,F+BigInt(position),F-BigInt(position));
}
check(cases===2062 && cells===14434 && legacyDifferences>0 && equalities>0 &&
  contexts.size===cases,"चाचणी संच किंवा legacy branches अपूर्ण");

// अलग स्वतंत्र state, frozen results, escaped mutable inputs.
const source=[1n,2n,3n,4n,5n,6n,7n];
const first=patch05HiddenDrops(F,F,source);
const second=patch05HiddenDrops(F,F,source);
source[0]=991n;
first.context.metrics.set("personal",91n);
first.context.logs.push("स्वतंत्र लॉग");
check(second.correctedReads.join(",")==="1,2,3,4,5,6,7" &&
  first.correctedReads.join(",")==="1,2,3,4,5,6,7" &&
  !second.context.metrics.has("personal") && second.context.logs.length===0 &&
  first.backwardStored!==second.backwardStored && first.context!==second.context,
  "अपवाद व परस्परविलगीकरण");
console.log(`STAGE_11_PATCH_05_PROPERTIES_PASS cases=${cases} slots=${cells} legacyDifferences=${legacyDifferences} legacyMatches=${equalities}`);
