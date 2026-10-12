import { patch11OrderLatch,discoverLegacyOrderMemory } from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,
  postStir12,bowlOrderFromDrop
} from "./normativeOracle.ts";
import { normativePostStirLedger } from "./discovery11Reference.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let cases=0,cells=0,mismatches=0,writes=0,latchWrites=0;
let oldDifferences=0,oldMatches=0;
let first84Differences=0,first84Matches=0;
const contexts=new Set<object>();
const distinctRankOrders=new Set<string>();
function checkRun(c:bigint,t:bigint,visible:readonly bigint[],
    start:readonly bigint[],stones:typeof STONES,kind:"real"|"varied"|"giant"|"rank"){
  const result=patch11OrderLatch(c,t,visible,stones,start);
  const reference=applyVisibleDropsToBowls(
    [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,stones);
  const post=normativePostStirLedger(reference.bowls);
  const complete=postStir12(
    [...reference.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
  cases++;writes+=result.sharedMemoryWrites;latchWrites+=result.latchCaptures;
  check(!contexts.has(result.context),"state per invocation is isolated");
  contexts.add(result.context);
  check(result.latchWriteIndex===46&&result.latchCaptures===1&&
    result.sharedMemoryWrites===58&&result.drops===46&&result.postStirs===12&&
    result.historical.ledger.length===58&&
    result.ledger[45]!.source==="DROP_46"&&
    result.ledger[57]!.source==="STIR_12"&&
    result.correctedQueryReads===1&&result.legacyQueryReads===1,
    "58 overwrites preserved with independent 46th-write latch");
  const expected=reference.orderAtDrop46;
  check(result.orderAt46Latch.join(",")===expected.join(",")&&
    result.orderAt46Latch.join(",")===bowlOrderFromDrop(visible[46]!).join(",")&&
    result.correctedQueryOrder.join(",")===expected.join(",")&&
    result.orderAt46Latch!==result.correctedQueryOrder&&
    result.legacyQueryOrder.join(",")===post.finalOrder.join(","),
    "semantics read cloned 46th order; wrong history reads 12th stir order");
  check(result.afterDropBowls.every((v,j)=>v===reference.bowls[j])&&
    result.finalBowls.every((v,j)=>v===post.finalBowls[j]&&v===complete[j]),
    "complete real 46 drop and 12 stir bowl results exact");
  for(let stir=0;stir<12;stir++){
    check(result.ledger[46+stir]!.order.join(",")===
      post.orders[stir]!.join(","),"all twelve historical post-stir writes unchanged");
  }
  for(let pos=1;pos<=6;pos++){
    cells++;
    if(result.correctedQueryOrder[pos-1]!==expected[pos-1])mismatches++;
  }
  if(kind!=="rank"){
    for(const pos of [1,2,6]){
      if(result.legacyQueryOrder[pos-1]===expected[pos-1]){
        oldMatches++;first84Matches++;
      }else{
        oldDifferences++;first84Differences++;
      }
    }
  }else{
    for(const pos of [1,2,6]){
      if(result.legacyQueryOrder[pos-1]===expected[pos-1])oldMatches++;
      else oldDifferences++;
    }
    distinctRankOrders.add(result.correctedQueryOrder.join(","));
  }
  check(result.context.metrics.get("patch11.latch_writes")===1n&&
    result.context.metrics.get("patch11.semantic_queries")===1n&&
    result.context.metrics.get("patch11.shared_memory_writes")===58n&&
    result.historical.context.metrics.get("discovery11.shared_order_writes")===58n,
    "separate patched and historical metrics");
}
let realPairs=0,varied=0,giant=0,ranks=0;
for(const [c,t] of pairs){
  const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
  const visible=buildVisibleDrops(counts,STONES,hidden);
  checkRun(c,t,visible,initialBowls(counts),STONES,"real");
  realPairs++;
}
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const baseline=buildVisibleDrops(counts,STONES,hidden);
const seed=initialBowls(counts);
for(let j=0;j<64;j++){
  const changed=[...baseline];
  changed[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
  changed[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
  checkRun(F+BigInt(j),F-BigInt(j),changed,seed,STONES,"varied");
  varied++;
}
const huge=(1n<<8192n)+193n;
const extreme=[huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)];
for(const d of extreme){
  const changed=[...baseline];changed[1]=d;changed[46]=-d+1n;
  const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
  checkRun(F-huge,F+huge,changed,b,STONES,"giant");giant++;
}
check(realPairs===12&&varied===64&&giant===8&&cases===84&&
  first84Differences===206&&first84Matches===46&&
  latchWrites===84&&writes===4872&&mismatches===0,
  "Stage22 full 84 histories retain exact 206 historical differences");

// Every 6! order can occur at DROP_46. This does not create a second latch:
// each independent run has just one snapshot after its real 46th write.
for(let rank=1n;rank<=720n;rank++){
  const changed=[...baseline];changed[46]=rank;
  checkRun(F,F,changed,seed,STONES,"rank");
  ranks++;
}
check(ranks===720&&distinctRankOrders.size===720&&
  cases===804&&cells===4824&&writes===46632&&
  latchWrites===804&&mismatches===0&&contexts.size===804&&
  oldDifferences+oldMatches===252+2160&&oldDifferences>206,
  "all 720 independent DROP46 permutations retained after each 12 post-stirs");

// The original historical helper and its nonzero expected-red evidence remain.
const legacy=discoverLegacyOrderMemory(F,F,baseline,STONES,seed);
const patched=patch11OrderLatch(F,F,baseline,STONES,seed);
check(legacy.legacyQueryOrder.join(",")===patched.legacyQueryOrder.join(",")&&
  legacy.ledger[57]!.order.join(",")===patched.ledger[57]!.order.join(",")&&
  legacy.ledger[45]!.order.join(",")===patched.orderAt46Latch.join(","),
  "same original 58 writes and last-stir query, but new semantic latch separate");
console.log(`STAGE_23_PATCH_11_PROPERTIES_PASS realPairs=${realPairs} varied=${varied} giant=${giant} ranks=${ranks} unique=${distinctRankOrders.size} cases=${cases} cells=${cells} mismatches=${mismatches} latchWrites=${latchWrites} sharedWrites=${writes} historicalDifferences=${oldDifferences} historicalMatches=${oldMatches} first84Differences=${first84Differences} first84Matches=${first84Matches}`);
