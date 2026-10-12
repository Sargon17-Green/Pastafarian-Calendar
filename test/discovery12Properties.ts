import { discoverLegacyFixedNextBowl,LegacyNextBowlFixedNameAdapter } from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
  initialBowls,applyVisibleDropsToBowls,postStir12,bowlOrderFromNumber,
  bowlOrderFromDrop
} from "./normativeOracle.ts";
import { canonicalNextBowl } from "./discovery12Reference.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg);}
const adapter=new LegacyNextBowlFixedNameAdapter();
let exhaustiveOrders=0,exhaustiveCells=0,exhaustiveWrong=0,exhaustiveMatches=0;
let numericWrapCases=0,positionWrapCases=0,lastPositionWrong=0;
const uniqueOrders=new Set<string>();
// Independent 720-order × every queried ID authoritative differential,
// including numeric bowl 6→1 and cyclic position-six→position-one.
for(let rank=1n;rank<=720n;rank++){
  const order=bowlOrderFromNumber(rank);
  uniqueOrders.add(order.join(","));
  exhaustiveOrders++;
  const last=order[5]!;
  check(canonicalNextBowl(order,last)===order[0],"cyclic last position to first");
  positionWrapCases++;
  check(adapter.oldNextBowlFixedName(6)===1,"numeric ID6 always wraps to 1");
  numericWrapCases++;
  if(adapter.oldNextBowlFixedName(last)!==order[0])lastPositionWrong++;
  for(let id=1;id<=6;id++){
    const old=adapter.oldNextBowlFixedName(id),want=canonicalNextBowl(order,id);
    check(old!==id&&want!==id&&
      order.includes(old)&&order.includes(want),
      "successors never self, each valid bowl ID");
    if(old===want)exhaustiveMatches++;else exhaustiveWrong++;
    exhaustiveCells++;
  }
}
check(uniqueOrders.size===720&&exhaustiveOrders===720&&
 exhaustiveCells===4320&&exhaustiveWrong===3456&&exhaustiveMatches===864&&
 numericWrapCases===720&&positionWrapCases===720&&lastPositionWrong===576,
 "exhaustive 6! successor grid: old numeric 3456 wrong and 864 coincidences");

const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const contexts=new Set<object>(),observedRanks=new Set<string>();
let histories=0,sharedWrites=0,queryMisses=0,queryMatches=0;
let realPairs=0,varied=0,giant=0,rankHistories=0,realWrong=0,realSame=0;
function verify(c:bigint,t:bigint,visible:readonly bigint[],
    start:readonly bigint[],stones:typeof STONES,queriedId:number,
    family:"real"|"varied"|"giant"|"rank"):void{
  const out=discoverLegacyFixedNextBowl(c,t,visible,stones,start,queriedId);
  const actualOrder=bowlOrderFromDrop(visible[46]!);
  const authoritative=canonicalNextBowl(actualOrder,queriedId);
  const reference=applyVisibleDropsToBowls(
    [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,stones);
  const final=postStir12(
    [...reference.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
  histories++;sharedWrites+=out.sharedMemoryWrites;
  check(!contexts.has(out.context),"no shared ownership across 804 real executions");
  contexts.add(out.context);
  check(out.queriedBowlId===queriedId&&
    out.legacyNextBowlId===(queriedId===6?1:queriedId+1)&&
    out.orderAt46Latch.join(",")===actualOrder.join(",")&&
    out.actualDrop46Order.join(",")===reference.orderAtDrop46.join(",")&&
    out.latchCaptures===1&&out.numericSuccessorCalls===1&&
    out.preceding.sharedMemoryWrites===58&&
    out.preceding.historical.memoryWrites===58&&
    out.preceding.historical.latestSource==="STIR_12"&&
    out.historicalOverwrittenOrder.join(",")===
       out.preceding.historical.legacyQueryOrder.join(",")&&
    out.context.status==="DISCOVERY_12_RECORDED",
    "real Stage23 latch, wrong numeric successor, 58 historical overwrites");
  check(out.afterDropBowls.every((v,j)=>v===reference.bowls[j])&&
    out.finalBowls.every((v,j)=>v===final[j]),
    "correct bowl arithmetic, only next-bowl numeric result is wrong");
  check(Object.isFrozen(out)&&Object.isFrozen(out.orderAt46Latch)&&
    Object.isFrozen(out.finalBowls)&&
    out.context.metrics.get("discovery12.legacy_successor_calls")===1n&&
    out.context.metrics.get("discovery12.preceding_58_write_sequences")===1n,
    "frozen state and true method accounting");
  if(out.legacyNextBowlId===authoritative){queryMatches++;if(family==="real")realSame++;}
  else{queryMisses++;if(family==="real")realWrong++;}
  if(family==="rank")observedRanks.add(out.orderAt46Latch.join(","));
}
for(const [c,t] of pairs){
 const count=workCounts(c,t),hidden=buildHiddenDrops(count,STONES);
 const visible=buildVisibleDrops(count,STONES,hidden),start=initialBowls(count);
 verify(c,t,visible,start,STONES,(realPairs%6)+1,"real");
 realPairs++;
}
const count=workCounts(F,F),hidden=buildHiddenDrops(count,STONES);
const baseline=buildVisibleDrops(count,STONES,hidden),start=initialBowls(count);
for(let j=0;j<64;j++){
  const changed=[...baseline];
  changed[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
  changed[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
  verify(F+BigInt(j),F-BigInt(j),changed,start,STONES,(j%6)+1,"varied");
  varied++;
}
const huge=(1n<<8192n)+193n;
const ds=[huge,-huge,huge*huge,-huge*huge,0n,720n,
  1n<<16384n,-(1n<<16384n)];
for(const d of ds){
  const changed=[...baseline];changed[1]=d;changed[46]=-d+1n;
  const b=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
  verify(F-huge,F+huge,changed,b,STONES,(giant%6)+1,"giant");
  giant++;
}
// Each of 720 distinct actual DROP46 rank streams goes through complete
// corrected Stage21/23 route but the old next-name numeric method stays wrong.
for(let rank=1n;rank<=720n;rank++){
  const changed=[...baseline];changed[46]=rank;
  verify(F,F,changed,start,STONES,(Number(rank)%6)+1,"rank");
  rankHistories++;
}
check(realPairs===12&&varied===64&&giant===8&&rankHistories===720&&
  histories===804&&sharedWrites===46632&&
  contexts.size===histories&&observedRanks.size===720&&
  queryMisses+queryMatches===804&&queryMisses>0&&queryMatches>0&&
  realWrong+realSame===12&&realWrong>0,
  "804 full 58-write numeric successor histories; all six factorial ranks");
console.log(`STAGE_24_DISCOVERY_12_PROPERTIES_PASS orders=${exhaustiveOrders} cells=${exhaustiveCells} wrong=${exhaustiveWrong} matches=${exhaustiveMatches} numericWrap=${numericWrapCases} positionWrap=${positionWrapCases} positionWrapWrong=${lastPositionWrong} realPairs=${realPairs} varied=${varied} giant=${giant} ranks=${rankHistories} unique=${observedRanks.size} histories=${histories} sharedWrites=${sharedWrites} queryWrong=${queryMisses} queryMatches=${queryMatches} realWrong=${realWrong} realMatches=${realSame}`);
