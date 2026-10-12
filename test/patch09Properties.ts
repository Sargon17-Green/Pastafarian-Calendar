import {
  patch09Pours, LegacyFixedBowlPoursAdapter, discoverLegacyFixedPours
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F, M, bowlOrderFromDrop, STONES, workCounts,
  buildHiddenDrops, buildVisibleDrops, initialBowls
} from "./normativeOracle.ts";
import { normativeThreePours } from "./discovery09Reference.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
const bowls=Object.freeze([101n,211n,307n,401n,503n,601n]);
const stone=Object.freeze([2n,3n,5n,7n,11n]);
const directOld=new LegacyFixedBowlPoursAdapter();
const seen=new Set<object>();
let cases=0,correctedCells=0,correctedMismatches=0;
let rankOrders=0,rankWrong=0,rankMatches=0;
function compare(c:bigint,t:bigint,i:number,d:bigint,b:readonly bigint[],s:readonly bigint[]):void{
  const obs=patch09Pours(c,t,i,d,b,s);
  const expected=normativeThreePours(i,d,b,s);
  const order=bowlOrderFromDrop(d);
  cases++;
  if(seen.has(obs.context))throw Error("context पुनर्वापर नाही");
  seen.add(obs.context);
  check(obs.order.join(",")===order.join(",") &&
    obs.bowlAlias.slice(1).join(",")===order.join(",") &&
    obs.bowlAlias[0]===0,"all six aliases exact");
  for(let pos=0;pos<6;pos++)
    check(obs.legacyPositionBowlView[pos]===b[order[pos]!-1],
      "six aliases read actual bowl IDs");
  const old=directOld.legacyFixedPours(c,t,i,d,b,s);
  for(let pos=0;pos<3;pos++){
    correctedCells++;
    if(obs.correctedPours[pos]!==expected[pos])correctedMismatches++;
    check(obs.historicalPours[pos]===old[pos],
      "original legacy result preserved unchanged");
  }
  check(obs.context.metrics.get("patch09.position_alias_reads")===6n &&
    obs.context.metrics.get("patch09.aliased_legacy_calls")===1n &&
    Object.isFrozen(obs.correctedPours),"old helper remapped and state measured");
}

// Exhaustive six factorial permutations, three pours each.
for(let drop=1n;drop<=720n;drop++){
  const obs=patch09Pours(F,F,7,drop,bowls,stone);
  const norm=normativeThreePours(7,drop,bowls,stone);
  compare(F,F,7,drop,bowls,stone);
  for(let p=0;p<3;p++){
    if(obs.historicalPours[p]===norm[p])rankMatches++;else rankWrong++;
  }
  rankOrders++;
}
check(rankOrders===720&&rankWrong===1800&&rankMatches===360 &&
  cases===720&&correctedCells===2160&&correctedMismatches===0,
  "all 720 permutations: old=1800 wrong, corrected=zero wrong");

// 12 real independent day pairs x 46 normative visible drops.
// 46-step evolving bowl state is postponed to later stages.
const pairs:readonly (readonly [bigint,bigint])[]=[
  [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
  [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
  [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let realPairs=0,realDrops=0,realCells=0,realWrong=0,realMatches=0;
for(const [c,t] of pairs){
  const counts=workCounts(c,t);
  const hidden=buildHiddenDrops(counts,STONES);
  const visible=buildVisibleDrops(counts,STONES,hidden);
  const inputBowls=initialBowls(counts);
  for(let i=1;i<=46;i++){
    const drop=visible[i]!;
    const result=patch09Pours(c,t,i,drop,inputBowls,STONES[i]!);
    const expected=normativeThreePours(i,drop,inputBowls,STONES[i]!);
    check(drop>=1n&&drop<=M,"real drops in SAVE range");
    compare(c,t,i,drop,inputBowls,STONES[i]!);
    for(let k=0;k<3;k++){
      if(result.historicalPours[k]===expected[k])realMatches++;else realWrong++;
      check(result.correctedPours[k]===expected[k],"real canonical drops exact");
      realCells++;
    }
    realDrops++;
  }
  realPairs++;
}
check(realPairs===12&&realDrops===552&&realCells===1656 &&
  realWrong===1383&&realMatches===273&&correctedMismatches===0,
  "real 12 pairs 552 drops: preserve Stage18 exact historical witness counts");

// Deterministic signed 256-bit inputs, independent bowl values.
let state=0x4fedcba987654321n;
const mask=(1n<<256n)-1n;
let seeded=0;
for(let run=0;run<2048;run++){
  const values:bigint[]=[];
  for(let k=0;k<12;k++){
    state=(state*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
    values.push((run+k)%2===0 ? state : -state);
  }
  const d=values[0]!,b=values.slice(1,7),s=values.slice(7,12);
  compare(F+BigInt(run),F-BigInt(run),(run%46)+1,d,b,s);
  seeded++;
}
check(seeded===2048&&cases===3320&&correctedMismatches===0,
  "signed diverse per-call aliasing");

// 16k-bit signed x bigger than 128-bit SAVE modulus.
const huge=(1n<<16384n)+193n;
const giantDrops=[huge,-huge,huge*huge,-huge*huge,0n,720n,
  (1n<<32768n),-(1n<<32768n)];
let giantCases=0;
for(const d of giantDrops){
  const b=[huge+11n,huge+23n,huge+37n,huge+41n,huge+53n,huge+67n];
  const s=[huge,-huge,3n*huge,5n*huge,-7n*huge];
  compare(F-huge,F+huge,46,d,b,s);
  giantCases++;
}
check(giantCases===8&&cases===3328&&correctedCells===9984&&
  correctedMismatches===0&&seen.size===cases,
  "giant signed, no oracle mismatches, no context leakage");
const archival=discoverLegacyFixedPours(F,F,7,120n,bowls,stone);
check(archival.legacyPours.join(",")===
  patch09Pours(F,F,7,120n,bowls,stone).historicalPours.join(","),
  "Stage18 deliberately-red historical path still wrong");
console.log(`STAGE_19_PATCH_09_PROPERTIES_PASS cases=${cases} cells=${correctedCells} mismatches=${correctedMismatches} rankOrders=${rankOrders} rankWrong=${rankWrong} rankMatches=${rankMatches} realPairs=${realPairs} realDrops=${realDrops} realWrong=${realWrong} realMatches=${realMatches} seeded=${seeded} giant=${giantCases}`);
