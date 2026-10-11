import {
  LegacyPermutationUnrankAdapter, patch08Permutation,
  discoverLegacyPermutation
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, workCounts, STONES,
  buildHiddenDrops, buildVisibleDrops,
  bowlOrderFromDrop, regularMod
} from "./normativeOracle.ts";

function check(ok:boolean,why:string):void {if(!ok)throw Error(why);}
const old=new LegacyPermutationUnrankAdapter();
let cases=0,shifted=0,rejected=0,mismatches=0;
const contexts=new Set<object>();
const distinct=new Set<string>();
function verify(drop:bigint,c:bigint,t:bigint):void{
  const o=patch08Permutation(c,t,drop);
  const expected=bowlOrderFromDrop(drop);
  const one=regularMod(drop-1n,720n)+1n;
  cases++;
  if(o.order.join(",")!==expected.join(","))mismatches++;
  check(o.oneBased===one && o.legacyRank0===one-1n &&
    o.order.every((v,j)=>v===old.oldPermutationUnrank0(o.legacyRank0)[j]) &&
    Object.isFrozen(o.order) && new Set(o.order).size===6,"correct normalized rank आणि old method");
  check(!contexts.has(o.context),"जुन्या calls ची state वेगळी");contexts.add(o.context);
  if(drop>=0n&&drop<720n){
    shifted++;
    check(!o.rawLegacyWouldReject && o.legacyRank0!==drop,
      "legacy raw rank ने off-by-one दिसावा");
  }else{
    rejected++;
    check(o.rawLegacyWouldReject,"legacy raw rank 0..719 बाहेर असावा");
  }
  distinct.add(o.order.join(","));
}

// सर्व 720 rank, -720, 0, 720, 1440 यांभोवती सुसंगत wraparound.
for(let i=-1440n;i<=2159n;i++)verify(i,F,F+1n);
check(cases===3600 && mismatches===0 && shifted===720 &&
  rejected===2880 && distinct.size===720,"3600 सर्व श्रेणी, 720 unique permutations");

// मोठे सकारात्मक/ऋण shifted signed bigint — deterministic arithmetic.
let state=0x7a3c52e8d199b10fn;
const mask=(1n<<256n)-1n;
let seeded=0;
for(let i=0;i<2048;i++){
  state=(state*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
  const d=(i%2===0?1n:-1n)*(state-(1n<<255n));
  verify(d,F+BigInt(i),F-BigInt(i));seeded++;
}
check(cases===5648 && mismatches===0,"2048 deterministic values");

// वास्तविक normative visible drops; इतर शाखा किंवा production मध्ये oracle आयात नाही.
let visibleDays=0,visibleCases=0;
const dayPairs:readonly (readonly [bigint,bigint])[]=[
  [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
  [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
  [-278522n,-278522n+10000n],[1n,1n],[100000n,-100000n],
  [-100000n,100000n]
];
for(const [c,t] of dayPairs){
  const count=workCounts(c,t);
  const hidden=buildHiddenDrops(count,STONES);
  const visible=buildVisibleDrops(count,STONES,hidden);
  for(let i=1;i<=46;i++){
    const d=visible[i]!;
    verify(d,c,t);
    check(d>=1n&&d<=M,"normative visible drop 1..M");
    visibleCases++;
  }
  visibleDays++;
}
check(visibleDays===12 && visibleCases===552 && cases===6200 &&
  mismatches===0,"12 actual normative pairs ×46 drops");

// signed giant bit-widths, न विखंडित केलेली bigints.
const huge=(1n<<16384n)+711n;
const giants=[huge,-huge,huge+719n,huge-1n,-huge+1n,
              huge*huge,-huge*huge,(1n<<32768n),-(1n<<32768n)];
let giantCases=0;
for(const drop of giants){
  verify(drop,F+huge,F-huge);
  const o=patch08Permutation(F,F,drop);
  check(o.oneBased>=1n&&o.oneBased<=720n &&
    o.legacyRank0>=0n&&o.legacyRank0<720n,"gigantic signed normalized");
  giantCases++;
}
check(giantCases===9 && cases===6209 && mismatches===0,"giants and wrapping");

const historic=discoverLegacyPermutation(F,F,720n);
check(!historic.legacyAccepted && historic.legacyRejection==="OUT_OF_RANGE" &&
  patch08Permutation(F,F,720n).order.join(",")===bowlOrderFromDrop(720n).join(","),
  "सात archive लाल आणि stage16 old raw behaviour कायम");
console.log(`STAGE_17_PATCH_08_PROPERTIES_PASS cases=${cases} shifted=${shifted} rejected=${rejected} mismatches=${mismatches} unique=${distinct.size} seeded=${seeded} visibleDays=${visibleDays} visibleCases=${visibleCases} giantCases=${giantCases}`);
