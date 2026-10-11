import {
  GRIND_TABLE_WITH_SENTINEL, LEGACY_GRIND_TABLE, patch07Grind, LegacyGrindTableAdapter,
  discoverLegacyGrind
} from "../src/index.ts";
import { FOUNDATION_DAY as F, M } from "./normativeOracle.ts";
import { normativeGrindStep, NORMATIVE_GRIND_ROWS } from "./discovery07Fixtures.ts";

function check(ok:boolean,why:string):void {if(!ok)throw Error(why);}
const adapter=new LegacyGrindTableAdapter();
let cases=0,legacyShifted=0,legacyMissing=0,mismatches=0,propertyRuns=0;
const contexts=new Set<object>();

function verifyAll(c:bigint,t:bigint,x:bigint,p1:bigint,p3:bigint,p7:bigint,stone:readonly bigint[]):void{
  for(let g=1;g<=11;g++){
    const res=patch07Grind(c,t,g,x,p1,p3,p7,stone);
    const expected=normativeGrindStep(g,x,p1,p3,p7,stone);
    cases++;
    if(res.correctedValue!==expected)mismatches++;
    check(!contexts.has(res.context),"सर्व cases मध्ये स्वतंत्र context");
    contexts.add(res.context);
    check(res.indexUsed===g && res.actualRow===GRIND_TABLE_WITH_SENTINEL[g] &&
      res.actualRow!.every((v,j)=>v===NORMATIVE_GRIND_ROWS[g-1]![j]),
      "indexed sentinel table अनुक्रम कायम");
    check(res.legacyReadOccurred && res.historicalRow===adapter.legacyRow(g) &&
      res.correctedValue>=1n && res.correctedValue<=M,"old adapter, SAVE सीमा");
    if(g===11){
      legacyMissing++;
      check(res.historicalRowMissing && res.historicalRow===undefined,
        "11 वर जुनी अनुपस्थित row");
    } else {
      legacyShifted++;
      check(!res.historicalRowMissing && res.historicalRow===LEGACY_GRIND_TABLE[g] &&
        res.historicalRow!==res.actualRow,"1..10 shifted history कायम");
    }
  }
  propertyRuns++;
}

// पूर्वीची 256 deterministic cases चाचणी प्रमाणे पुन्हा वापरा.
const equalStone=Object.freeze([17n,17n,17n,17n,17n]);
for(let run=0;run<256;run++){
  const x=BigInt(run+11),p1=BigInt(17+run*3),
        p3=BigInt(23+run*5),p7=BigInt(31+run*7);
  verifyAll(F+BigInt(run),F-BigInt(run),x,p1,p3,p7,equalStone);
}
check(propertyRuns===256 && cases===2816 && mismatches===0 &&
  legacyShifted===2560 && legacyMissing===256,"stage 14 fixtures आता पूर्ण GREEN");

// मोठी signed व negative अवस्था, आणि 1024 deterministic seeded rows.
let state=0x1234abcd7890ef12n;
const mask=(1n<<256n)-1n;
for(let run=0;run<1024;run++){
  const v:bigint[]=[];
  for(let k=0;k<9;k++){
    state=(state*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
    v.push((k%2===0?1n:-1n)*(state-(1n<<255n)));
  }
  verifyAll(F+v[0]!,F-v[1]!,v[2]!,v[3]!,v[4]!,v[5]!,v.slice(4,9));
}
check(propertyRuns===1280 && cases===14080 && mismatches===0,
  "signed deterministic विविधता");

// क्रमाने 11 grind च्या वास्तविक chaining मध्ये प्रत्येक पुढील oldX
// मागील योग्य SAVE परिणामावरूनच घेतले जात आहे, हे end-to-end local प्रमाण.
let chainCases=0,chainGrinds=0,chainMismatches=0;
for(let run=0;run<64;run++){
  const c=F+BigInt(run*53-1000),t=F+BigInt(run*67-500);
  const stone=[11n+BigInt(run),13n+BigInt(run),17n+BigInt(run),19n+BigInt(run),23n+BigInt(run)];
  const p1=BigInt(run*17+31),p3=BigInt(run*29+43),p7=BigInt(run*41+59);
  let actual=BigInt(101+run),reference=actual;
  for(let g=1;g<=11;g++){
    actual=patch07Grind(c,t,g,actual,p1,p3,p7,stone).correctedValue;
    reference=normativeGrindStep(g,reference,p1,p3,p7,stone);
    if(actual!==reference)chainMismatches++;
    chainGrinds++;
  }
  chainCases++;
}
check(chainCases===64 && chainGrinds===704 && chainMismatches===0,
  "11 successive grinds मध्ये संदर्भाशी तंतोतंत समान");

// 8192-bit signed values, both directions, not a downcast.
const huge=(1n<<8192n)+31n;
let giantCases=0,giantMismatches=0;
for(const sign of [-1n,1n] as const){
  const x=sign*huge,p1=-huge,p3=huge+17n,p7=huge-23n;
  const stone=Object.freeze([huge,-huge,3n*huge,0n,-3n*huge]);
  for(let g=1;g<=11;g++){
    const result=patch07Grind(F-huge,F+huge,g,x,p1,p3,p7,stone);
    const expected=normativeGrindStep(g,x,p1,p3,p7,stone);
    if(result.correctedValue!==expected)giantMismatches++;
    giantCases++;
    check(result.historicalRow===adapter.legacyRow(g),"ऐतिहासिक index shadow");
  }
}
check(giantCases===22 && giantMismatches===0,"मोठे bigint, 11 वा sentinel आधारित grind");

// पूर्वीच्या archival discovery चे उत्तर कुठेही बदललेले नाही.
for(const g of [1,5,10,11]){
  const x=17n,p1=29n,p3=43n,p7=71n,stone=[101n,103n,107n,109n,113n];
  const old=discoverLegacyGrind(F,F,g,x,p1,p3,p7,stone);
  const corrected=patch07Grind(F,F,g,x,p1,p3,p7,stone);
  check(old.legacyValue!==corrected.correctedValue,"archive सदोषच असावी");
}
check(cases===14080 && propertyRuns===1280 && legacyShifted===12800 &&
  legacyMissing===1280 && mismatches===0,"पूर्ण 1280x11 set");
console.log(`STAGE_15_PATCH_07_PROPERTIES_PASS runs=${propertyRuns} cases=${cases} shifted=${legacyShifted} missing=${legacyMissing} mismatches=${mismatches} chains=${chainCases} chainedGrinds=${chainGrinds} chainMismatches=${chainMismatches} giantCases=${giantCases} giantMismatches=${giantMismatches}`);
