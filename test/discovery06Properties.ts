import {
  LegacyVisiblePriorAdapter, discoverLegacyPrior, MonsterValidationError
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, STONES, buildHiddenDrops, buildVisibleDrops, workCounts
} from "./normativeOracle.ts";

function check(ok:boolean,why:string):void { if(!ok)throw Error(why); }
const helper=new LegacyVisiblePriorAdapter();
let cases=0,hiddenMisses=0,visibleMatches=0,realDays=0;
const contexts=new Set<object>();
for(let run=0;run<16;run++){
  const c=F+BigInt(run*17-133),t=F+BigInt(run*29-251);
  const counts=workCounts(c,t);
  const hidden=buildHiddenDrops(counts,STONES);
  const visible=buildVisibleDrops(counts,STONES,hidden);
  realDays++;
  for(let i=1;i<=46;i++)for(const back of [1,3,7] as const){
    const slot=i-back;
    const expected=slot>=1 ? visible[slot] : hidden[1-slot];
    const observed=discoverLegacyPrior(c,t,visible,i,back);
    check(!contexts.has(observed.context),"स्वतंत्र संदर्भ आवश्यक");
    contexts.add(observed.context);
    check(observed.legacyValue===helper.legacyPrior(visible,i,back),
      "जुन्या थेट indexing helper शी तंतोतंत जुळले पाहिजे");
    check(observed.inputVisibleStore[i-1]===visible[i-1] &&
      observed.inputVisibleStore!==visible,
      "visible store चे input ownership बदलता कामा नये");
    if(slot<1) {
      check(observed.legacyValue===undefined && !observed.legacyFound &&
        typeof expected==="bigint", "hidden history ची जुनी चूक कायम");
      hiddenMisses++;
    } else {
      check(observed.legacyValue===expected && observed.legacyFound,
        "सकारात्मक visible history मध्ये जुन्या क्रियेचा अर्थ अचूक");
      visibleMatches++;
    }
    cases++;
  }
}
check(realDays===16 && cases===2208 && hiddenMisses===176 && visibleMatches===2032,
  "16 दिवस-जोड्यांवर सर्व 46*3 इतिहास स्लॉट");

// मोठ्या bigint चे values थेट positive slot मधून वाचता आले पाहिजेत.
const huge=(1n<<16384n)+193n;
const dropStore:(bigint|undefined)[]=Array.from({length:47},(_,j)=>
  j===0?undefined:huge+BigInt(j)*101n
);
for(let i=1;i<=46;i++)for(const back of [1,3,7] as const) {
  const slot=i-back,received=helper.legacyPrior(dropStore,i,back);
  check(received===(slot>=1?dropStore[slot]:undefined),
    "मोठ्या bigint साठी साधे जुने array indexing अपरिवर्तित");
}
// Sparse positive slot ला guarded handler नाकारते, तर raw legacy थेट undefined देतो.
const incomplete:(bigint|undefined)[]=[undefined,11n];
check(helper.legacyPrior(incomplete,2,1)===11n,"positive stored history");
check(helper.legacyPrior(incomplete,3,1)===undefined,"raw legacy undefined");
let rejected=false;
try{discoverLegacyPrior(F,F,incomplete,3,1)}catch(e){rejected=e instanceof MonsterValidationError}
check(rejected,"तयार नसलेला visible history slot सुरक्षितपणे नाकारावा");

const left=discoverLegacyPrior(F,F,dropStore,1,7);
const right=discoverLegacyPrior(F,F,dropStore,1,7);
left.context.logs.push("पहिली नोंद");
left.context.metrics.set("private",19n);
check(right.context.logs.length===0 && !right.context.metrics.has("private") &&
  left.context!==right.context && left.inputVisibleStore!==right.inputVisibleStore,
  "call क्रम व ownership neutral");

console.log(`STAGE_12_DISCOVERY_06_PROPERTIES_PASS days=${realDays} cases=${cases} hiddenMisses=${hiddenMisses} visibleMatches=${visibleMatches}`);
