import { LegacyGrindTableAdapter, discoverLegacyGrind, MonsterValidationError } from "../src/index.ts";
import { FOUNDATION_DAY as F, SAVE } from "./normativeOracle.ts";
import { NORMATIVE_GRIND_ROWS, normativeGrindStep } from "./discovery07Fixtures.ts";

function check(ok:boolean,why:string):void { if(!ok)throw Error(why); }
const oldAdapter=new LegacyGrindTableAdapter();
let cases=0,shifted=0,missing=0,differences=0,realSamples=0;
const contexts=new Set<object>();
const max=(1n<<127n)-1n;

// सर्व गुणांक सकारात्मक वाढतात; सर्व पाच दगड समान ठेवल्याने प्रत्येक
// शिफ्ट झालेल्या ओळीचे numeric अंतर हमखास दिसेल; SAVE मध्ये wrap होणार नाही.
const equalStone=Object.freeze([17n,17n,17n,17n,17n]);
for(let run=0;run<256;run++) {
  const x=BigInt(run+11), p1=BigInt(17+run*3), p3=BigInt(23+run*5), p7=BigInt(31+run*7);
  for(let g=1;g<=11;g++) {
    const actual=discoverLegacyGrind(F+BigInt(run),F-BigInt(run),g,x,p1,p3,p7,equalStone);
    const correct=normativeGrindStep(g,x,p1,p3,p7,equalStone);
    cases++;
    check(!contexts.has(actual.context),"प्रत्येक call स्वतंत्र context");
    contexts.add(actual.context);
    if(actual.legacyValue!==correct)differences++;
    if(g===11) {
      missing++;
      check(!actual.rowPresent && actual.legacyValue===undefined,
        "sentinel नसल्याने शेवटची ओळ मिळू नये");
    } else {
      shifted++;
      const row=oldAdapter.legacyRow(g)!;
      const shiftedValue=SAVE(x*x+row[0]*x+row[1]*p1+
        row[2]*p3+row[3]*p7+equalStone[row[4]]!);
      check(actual.rowPresent && actual.legacyValue===shiftedValue &&
        shiftedValue!==correct,"चुकीचे 1-based indexing आणि अंकगणितातील फरक");
    }
  }
  realSamples++;
}
check(realSamples===256 && cases===2816 && shifted===2560 &&
  missing===256 && differences===2816,"पूर्ण 256x11 deterministic लाल साक्षी");

// अजूनही signed व विशाल पूर्णांकांसाठी numeric पुरावा; दुरुस्ती इथे नको.
const huge=(1n<<8192n)+31n;
let giantCases=0,giantValueChecks=0;
for(const sign of [-1n,1n] as const) {
  const x=sign*huge,p1=-huge,p3=huge+17n,p7=huge-23n;
  const stone=Object.freeze([huge,-huge,3n*huge,0n,-3n*huge]);
  for(let g=1;g<=11;g++) {
    const actual=discoverLegacyGrind(F-huge,F+huge,g,x,p1,p3,p7,stone);
    const expected=normativeGrindStep(g,x,p1,p3,p7,stone);
    if(g<11) {
      const row=oldAdapter.legacyRow(g)!;
      const historic=SAVE(x*x+row[0]*x+row[1]*p1+
        row[2]*p3+row[3]*p7+stone[row[4]]!);
      check(actual.legacyValue===historic,"प्रचंड bigint ने जुनी टेबल गणना बदलू नये");
      giantValueChecks++;
    } else check(actual.legacyValue===undefined,"अकरावी ऐतिहासिक ओळ गहाळ");
    check(expected>=1n && expected<=max,"स्वच्छ SAVE च्या सीमा");
    giantCases++;
  }
}
check(giantCases===22 && giantValueChecks===20,"8192-bit साक्षी");
console.log(`STAGE_14_DISCOVERY_07_PROPERTIES_PASS cases=${cases} shifted=${shifted} missing=${missing} differences=${differences} giantCases=${giantCases} giantValues=${giantValueChecks}`);
