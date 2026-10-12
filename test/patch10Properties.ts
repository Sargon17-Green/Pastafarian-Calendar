import { patch10Stir, discoverLegacyInPlaceStir } from "../src/index.ts";
import {
  FOUNDATION_DAY as F,M,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,applyVisibleDropsToBowls
} from "./normativeOracle.ts";
import { normativeSingleStir } from "./discovery10Reference.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
const bowls=[101n,211n,307n,401n,503n,601n],stone=[2n,3n,5n,7n,11n];
const contexts=new Set<object>();
let cases=0,cells=0,mismatches=0,oldWrong=0,oldMatches=0;
let vaultReads=0,pendingWrites=0,committedWrites=0;
function verify(c:bigint,t:bigint,i:number,d:bigint,b:readonly bigint[],s:readonly bigint[]):void{
  const res=patch10Stir(c,t,i,d,b,s);
  const expected=normativeSingleStir(i,d,b,s);
  cases++;
  check(!contexts.has(res.context),"independent state");contexts.add(res.context);
  check(res.order.join(",")===expected.order.join(",")&&
    res.pour.slice(0,3).join(",")===expected.pours.join(",")&&
    res.vaultOld.every((v,j)=>v===b[j])&&
    res.pending.every((v,j)=>v===res.correctedBowls[j]),
    "correct permutation/pours, original vault unchanged, explicit pending commit");
  check(res.correctedSteps.length===6&&res.oldMethodCalls===1&&
    res.stagedWrites===6&&res.committedWrites===6&&
    res.historicalReadContaminations===6,
    "six-position staging, real legacy shadow, final commit");
  for(let k=0;k<6;k++){
    const id=res.order[k]!;
    const step=res.correctedSteps[k]!;
    const prev=res.order[(k+5)%6]!,next=res.order[(k+1)%6]!;
    cells++;vaultReads++;pendingWrites++;committedWrites++;
    check(step.bowlId===id&&step.previousId===prev&&step.nextId===next&&
      step.currentRead===b[id-1]&&
      step.previousRead===b[prev-1]&&
      step.nextRead===b[next-1]&&
      step.stagedValue===expected.expectedSteps[k]&&
      step.stagedValue===res.pending[id-1],
      "all reads from vaultOld, never staged or committed values");
    if(res.correctedBowls[id-1]!==expected.expectedBowls[id-1])mismatches++;
    if(res.historicalBowls[id-1]===expected.expectedBowls[id-1])oldMatches++;
    else oldWrong++;
  }
}
for(let drop=1n;drop<=720n;drop++)verify(F,F,7,drop,bowls,stone);
check(cases===720&&cells===4320&&mismatches===0&&oldWrong===3600&&
  oldMatches===720,"all six factorial orders old scar still visible");
const orderCases=cases,orderOldWrong=oldWrong,orderOldMatches=oldMatches;

// Actual date-pair visible drops and complete evolving 46-step state.
const pairs:readonly (readonly [bigint,bigint])[]=[
  [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
  [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
  [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let realPairs=0,realDrops=0,evolvingPairs=0,evolvingDrops=0,evolvingMismatches=0;
let historicalFinalMismatches=0;
for(const [c,t] of pairs){
  const counts=workCounts(c,t);
  const hidden=buildHiddenDrops(counts,STONES);
  const visible=buildVisibleDrops(counts,STONES,hidden);
  const initial=initialBowls(counts);
  for(let i=1;i<=46;i++){
    const drop=visible[i]!;
    check(drop>=1n&&drop<=M,"normative visible drops in SAVE range");
    verify(c,t,i,drop,initial,STONES[i]!);
    realDrops++;
  }
  realPairs++;

  let corrected:readonly bigint[]=[...initial];
  let historical:readonly bigint[]=[...initial];
  let oracle:readonly bigint[]=[...initial];
  for(let i=1;i<=46;i++){
    const drop=visible[i]!;
    const patch=patch10Stir(c,t,i,drop,corrected,STONES[i]!);
    const old=discoverLegacyInPlaceStir(c,t,i,drop,historical,STONES[i]!);
    const ref=normativeSingleStir(i,drop,oracle,STONES[i]!);
    corrected=patch.correctedBowls;
    historical=old.legacyBowls;
    oracle=ref.expectedBowls;
    check(corrected.every((v,j)=>v===oracle[j]),
      "every intermediate evolving 46-step state equals normative reference");
    evolvingDrops++;
  }
  const fullOracle=applyVisibleDropsToBowls(
    [...initial] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
  check(corrected.every((v,j)=>v===fullOracle.bowls[j]),
    "whole 46-drop patched sequence equals independent full 46-step oracle");
  const changed=historical.reduce((n,v,j)=>n+Number(v!==corrected[j]),0);
  check(changed===6,"historical evolving sequence differs in all final six bowls");
  historicalFinalMismatches+=changed;
  evolvingPairs++;
}
check(realPairs===12&&realDrops===552&&evolvingPairs===12&&evolvingDrops===552&&
  historicalFinalMismatches===72&&evolvingMismatches===0&&
  cases===1272&&cells===7632&&mismatches===0,
  "12 complete day-pairs, 552 real drops, all 72 old wrong final bowls");

// Unbiased seeded signed 256-bit input, independent bowl/stone.
let seed=0x4fedcba987654321n,seeded=0;
const mask=(1n<<256n)-1n;
for(let run=0;run<1024;run++){
  const values:bigint[]=[];
  for(let k=0;k<12;k++){
    seed=(seed*0x5851f42d4c957f2dn+0x14057b7ef767814fn)&mask;
    values.push((run+k)%2===0?seed:-seed);
  }
  verify(F+BigInt(run),F-BigInt(run),(run%46)+1,
    values[0]!,values.slice(1,7),values.slice(7,12));
  seeded++;
}
check(seeded===1024&&cases===2296&&mismatches===0,"1024 seeded signed cases");

const huge=(1n<<8192n)+193n;
const drops=[huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)];
let giant=0;
for(const d of drops){
  const b=[huge+11n,huge+23n,huge+37n,huge+41n,huge+53n,huge+67n];
  const s=[huge,-huge,3n*huge,5n*huge,-7n*huge];
  verify(F-huge,F+huge,46,d,b,s);
  giant++;
}
check(giant===8&&cases===2304&&cells===13824&&
  mismatches===0&&oldWrong===11520&&oldMatches===2304&&
  vaultReads===13824&&pendingWrites===13824&&committedWrites===13824&&
  contexts.size===cases,"full 2304 cases, 13824 reads, staged and commit writes; zero mismatches");
console.log(`STAGE_21_PATCH_10_PROPERTIES_PASS orders=${orderCases} orderWrong=${orderOldWrong} orderMatches=${orderOldMatches} cases=${cases} cells=${cells} mismatches=${mismatches} oldWrong=${oldWrong} oldMatches=${oldMatches} vaultReads=${vaultReads} pendingWrites=${pendingWrites} committedWrites=${committedWrites} realPairs=${realPairs} realDrops=${realDrops} evolvingPairs=${evolvingPairs} evolvingDrops=${evolvingDrops} evolvingMismatches=${evolvingMismatches} historicalFinalMismatches=${historicalFinalMismatches} seeded=${seeded} giant=${giant}`);
