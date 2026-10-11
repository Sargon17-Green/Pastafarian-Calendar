import {
  LegacyBackwardHiddenAdapter, LegacyVisiblePriorAdapter, patch06Prior,
  Patch05HiddenHandler
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, STONES, buildHiddenDrops, buildVisibleDrops, workCounts
} from "./normativeOracle.ts";

function check(ok:boolean,why:string):void { if(!ok) throw new Error(why); }
const hiddenStorage=new LegacyBackwardHiddenAdapter();
const hiddenReader=new Patch05HiddenHandler();
const legacy=new LegacyVisiblePriorAdapter();
let cases=0, days=0, hidden=0, visible=0, mismatches=0;
const contexts=new Set<object>();

for(let run=0;run<16;run++) {
  const c=F+BigInt(run*17-133),t=F+BigInt(run*29-251);
  const counts=workCounts(c,t);
  const hiddenOracle=buildHiddenDrops(counts,STONES);
  const visibleOracle=buildVisibleDrops(counts,STONES,hiddenOracle);
  const reversed=hiddenStorage.storeBackward(Array.from({length:7},(_,j)=>hiddenOracle[j+1]!));
  days++;
  for(let i=1;i<=46;i++)for(const back of [1,3,7] as const) {
    const slot=i-back;
    const expected=slot>=1?visibleOracle[slot]!:hiddenOracle[1-slot]!;
    const got=patch06Prior(c,t,visibleOracle,reversed,i,back);
    cases++;
    if(got.correctedValue!==expected)mismatches++;
    check(!contexts.has(got.context),"सर्व 2208 call स्वतंत्र");
    contexts.add(got.context);
    check(got.inputVisibleStore!==visibleOracle && got.inputBackwardStored!==reversed,
      "दोन स्वतंत्र snapshots");
    check(Object.isFrozen(got) && Object.isFrozen(got.inputVisibleStore) &&
      Object.isFrozen(got.inputBackwardStored),"immutable परिणाम");
    check(got.inputBackwardStored[0]===reversed[0] &&
      got.inputVisibleStore[i]===visibleOracle[i],"स्रोत माहिती बदलू नये");
    if(slot>=1) {
      visible++;
      check(got.legacyCalled && got.legacyValue===legacy.legacyPrior(visibleOracle,i,back) &&
        got.correctedValue===got.legacyValue,"सकारात्मक इतिहासात मूळ call");
    } else {
      hidden++;
      const k=1-slot;
      check(!got.legacyCalled && got.legacyValue===undefined &&
        got.hiddenK===k && got.hiddenStorageIndexZeroBased===7-k &&
        got.correctedValue===hiddenReader.correctedHiddenAt(reversed,k),
        "0 व ऋण slots साठी उलटा stored hidden");
    }
  }
}
check(days===16 && cases===2208 && hidden===176 && visible===2032 && mismatches===0 &&
  contexts.size===cases,"सर्व 16 दिवस-जोड्यांची exhaustive शाखा पडताळणी");

// फार मोठ्या signed bigint ने hidden, visible व storage slots बदलू नयेत.
const big=(1n<<16384n)+193n;
const hugeHidden=[big,-big,big+1n,-big-1n,0n,123n,-123n];
const hugeReversed=hiddenStorage.storeBackward(hugeHidden);
const hugeVisible:(bigint|undefined)[]=Array.from({length:47},(_,j)=>
  j===0?undefined:(j%2?big:-big)+BigInt(j)
);
let giantCases=0,giantMismatches=0;
for(let i=1;i<=46;i++)for(const back of [1,3,7] as const) {
  const slot=i-back;
  const actual=patch06Prior(F-(1n<<8192n),F+(1n<<8192n),
    hugeVisible,hugeReversed,i,back);
  const expected=slot>=1?hugeVisible[slot]!:hugeHidden[-slot]!;
  if(actual.correctedValue!==expected)giantMismatches++;
  giantCases++;
}
check(giantCases===138 && giantMismatches===0,"16K bit मोठे व ऋण पूर्णांक");

const sentinel=[11n,13n,17n,19n,23n,29n,31n];
const backward=hiddenStorage.storeBackward(sentinel);
for(let k=1;k<=7;k++) {
  const i=8-k;
  const back=7;
  const obs=patch06Prior(F,F,[],backward,i,back);
  check(obs.hiddenK===k && obs.correctedValue===sentinel[k-1] &&
    obs.hiddenStorageIndexZeroBased===7-k,"hidden सातही उलट स्थानांवर");
}
const source=[undefined,11n,12n] as (bigint|undefined)[];
const a=patch06Prior(F,F,source,backward,2,1);
const b=patch06Prior(F,F,source,backward,2,1);
source[1]=991n;
a.context.warnings.push("पहिला");
check(a.correctedValue===11n && b.correctedValue===11n &&
  a.inputVisibleStore[1]===11n && b.inputVisibleStore[1]===11n &&
  a.context!==b.context && b.context.warnings.length===0,
  "call आणि caller mutation निरपेक्षता");

console.log(`STAGE_13_PATCH_06_PROPERTIES_PASS days=${days} cases=${cases} hidden=${hidden} visible=${visible} mismatches=${mismatches} giantCases=${giantCases} giantMismatches=${giantMismatches}`);
