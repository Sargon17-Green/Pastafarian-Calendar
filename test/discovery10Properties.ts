import {
  discoverLegacyInPlaceStir, patch09Pours, LegacyInPlaceBowlStirAdapter
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls
} from "./normativeOracle.ts";
import { normativeSingleStir } from "./discovery10Reference.ts";
function check(ok:boolean,why:string){if(!ok)throw Error(why);}
const b=[101n,211n,307n,401n,503n,601n],s=[2n,3n,5n,7n,11n];
let cases=0,cells=0,mismatches=0,matches=0,overwritten=0;
const contexts=new Set<object>();
function checkOne(c:bigint,t:bigint,i:number,d:bigint,bowls:readonly bigint[],stone:readonly bigint[]):void{
 const old=discoverLegacyInPlaceStir(c,t,i,d,bowls,stone);
 const oracle=normativeSingleStir(i,d,bowls,stone);
 cases++;
 check(old.order.join(",")===oracle.order.join(",")&&
  old.pour.slice(0,3).join(",")===oracle.pours.join(",")&&
  old.pour.slice(3).every(v=>v===0n),"alias-corrected pours, in-place bug only");
 check(!contexts.has(old.context),"isolated states");contexts.add(old.context);
 check(old.overwrittenReadSlots===6&&old.contaminatedPositions===5&&
  old.steps.length===6,"exact overwrites: 5 prev, 1 next");
 overwritten+=old.overwrittenReadSlots;
 for(let pos=0;pos<6;pos++){
  const id=old.order[pos]!;
  const equal=old.legacyBowls[id-1]===oracle.expectedBowls[id-1];
  cells++;
  if(equal)matches++;else mismatches++;
  check(equal===(pos===0),"only first step unaffected by in-place mutation");
  const trace=old.steps[pos]!;
  check(trace.position===pos+1&&trace.bowlId===id&&
    trace.previousAlreadyWritten===(pos>0)&&
    trace.nextAlreadyWritten===(pos===5),
    "read contamination structurally grounded in write order");
 }
}
// पूर्ण 720 permutation orders × 6 positions: 3600 old differences.
for(let rank=1n;rank<=720n;rank++)checkOne(F,F,7,rank,b,s);
check(cases===720&&cells===4320&&mismatches===3600&&matches===720&&
  overwritten===4320,"all 720 permutations and 4320 overwritten-read slots");
const rankMismatches=mismatches,rankMatches=matches;

// 12 date pairs x 46 normative visible drops, each independent from initial bowls.
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let realPairs=0,realDrops=0,realErrors=0;
let evolvingPairs=0,evolvingDrops=0,evolvingMismatches=0;
for(const [c,t] of pairs){
 const counts=workCounts(c,t);
 const hidden=buildHiddenDrops(counts,STONES);
 const visible=buildVisibleDrops(counts,STONES,hidden);
 const start=initialBowls(counts);
 for(let i=1;i<=46;i++){
  const drop=visible[i]!;
  check(drop>=1n&&drop<=M,"real visible drop SAVE range");
  const before=mismatches;
  checkOne(c,t,i,drop,start,STONES[i]!);
  realErrors+=mismatches-before;
  realDrops++;
 }
 realPairs++;
 // 46-step *evolving* comparison: historical in-place path versus
 // independent normative oracle, both starting with the identical bowls.
 let oldState:readonly bigint[]=[...start];
 let expectedState:readonly bigint[]=[...start];
 for(let i=1;i<=46;i++){
  const drop=visible[i]!;
  const old=discoverLegacyInPlaceStir(c,t,i,drop,oldState,STONES[i]!);
  const expected=normativeSingleStir(i,drop,expectedState,STONES[i]!);
  oldState=old.legacyBowls;
  expectedState=expected.expectedBowls;
  evolvingDrops++;
 }
 const canonical=applyVisibleDropsToBowls([...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 check(expectedState.join(",")===canonical.bowls.join(","),
  "reference individual 46-step evolution equals complete normative oracle");
 const different=oldState.reduce((n,v,j)=>n+Number(v!==expectedState[j]),0);
 check(different>0,"in-place historical evolution remains materially wrong");
 evolvingMismatches+=different;
 evolvingPairs++;
}
check(realPairs===12&&realDrops===552&&realErrors===2760&&
 evolvingPairs===12&&evolvingDrops===552&&evolvingMismatches>0,
 "12 day-pairs 552 real drops + 552 evolving legacy steps");

// Deterministic signed 256-bit multi-bowl/metamorphic cases.
let state=0x4fedcba987654321n;
const mask=(1n<<256n)-1n;
let seeded=0;
for(let run=0;run<1024;run++){
 const values:bigint[]=[];
 for(let k=0;k<12;k++){
  state=(state*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
  values.push((run+k)%2===0?state:-state);
 }
 checkOne(F+BigInt(run),F-BigInt(run),(run%46)+1,
  values[0]!,values.slice(1,7),values.slice(7,12));
 seeded++;
}
check(seeded===1024,"1024 seeded signed stress cases");

// Very large signed integers, exact bigint SAVE arithmetic.
const huge=(1n<<8192n)+193n;
const giantDrops=[huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)];
let giant=0;
for(const d of giantDrops){
 const bowls=[huge+11n,huge+23n,huge+37n,huge+41n,huge+53n,huge+67n];
 const stone=[huge,-huge,3n*huge,5n*huge,-7n*huge];
 checkOne(F-huge,F+huge,46,d,bowls,stone);
 giant++;
}
check(giant===8&&cases===2304&&cells===13824&&
 matches===2304&&mismatches===11520&&overwritten===13824&&
 contexts.size===cases,"single-drop exact counters and no shared contexts");
console.log(`STAGE_20_DISCOVERY_10_PROPERTIES_PASS orders=720 rankCells=4320 rankMismatches=${rankMismatches} rankMatches=${rankMatches} cases=${cases} cells=${cells} mismatches=${mismatches} matches=${matches} overwritten=${overwritten} realPairs=${realPairs} realDrops=${realDrops} realErrors=${realErrors} evolvingPairs=${evolvingPairs} evolvingDrops=${evolvingDrops} evolvingMismatches=${evolvingMismatches} seeded=${seeded} giant=${giant}`);
