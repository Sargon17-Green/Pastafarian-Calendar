import { discoverLegacyOrderMemory, LegacySharedOrderMemoryAdapter } from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,postStir12 } from "./normativeOracle.ts";
import { normativePostStirLedger } from "./discovery11Reference.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
const contexts=new Set<object>();
let cases=0,writes=0,dropRounds=0,postStirs=0,ledgerCells=0;
let queryDifferences=0,queryMatches=0,threePositionWitnesses=0;
function verify(c:bigint,t:bigint,visible:readonly bigint[],
  start:readonly bigint[],stones:typeof STONES):void{
  const obs=discoverLegacyOrderMemory(c,t,visible,stones,start);
  const normativeDrops=applyVisibleDropsToBowls(
    [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,stones);
  const normativePost=normativePostStirLedger(normativeDrops.bowls);
  const complete=postStir12([...normativeDrops.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
  cases++;
  check(!contexts.has(obs.context)&&obs.context.status==="DISCOVERY_11_RECORDED",
    "owned context per run");contexts.add(obs.context);
  check(obs.memoryWrites===58&&obs.queryReads===1&&obs.dropRounds===46&&
    obs.postStirRounds===12&&obs.latestSource==="STIR_12"&&
    obs.ledger.length===58,"all 58 actual writes complete, query last source");
  check(obs.afterDropBowls.every((v,j)=>v===normativeDrops.bowls[j])&&
    obs.finalBowls.every((v,j)=>v===normativePost.finalBowls[j]&&v===complete[j]),
    "exact final bowls after actual 46 patched drops plus 12 post-stirs");
  check(obs.ledger[45]!.order.join(",")===normativeDrops.orderAtDrop46.join(",")&&
    obs.legacyQueryOrder.join(",")===normativePost.finalOrder.join(",")&&
    obs.legacyQueryOrder.join(",")===obs.ledger[57]!.order.join(","),
    "old general memory query last order; forensic drop46 stays evidence only");
  check(obs.ledger.every((e,k)=>e.index===k+1&&
    e.source===(k<46?"DROP_"+(k+1):"STIR_"+(k-45))&&
    e.order.length===6&&new Set(e.order).size===6),
    "ledger exact write order and shape");
  for(let stir=0;stir<12;stir++){
    check(obs.ledger[46+stir]!.order.join(",")===
      normativePost.orders[stir]!.join(","),
      "every post-stir order is the normative computed order");
  }
  for(let k=0;k<58;k++){
    check(Object.isFrozen(obs.ledger[k])&&Object.isFrozen(obs.ledger[k]!.order),
      "forensic entries deeply immutable");
    ledgerCells+=6;
  }
  let redThree=true;
  for(const p of [1,2,6]){
    if(obs.legacyQueryOrder[p-1]===normativeDrops.orderAtDrop46[p-1]){
      queryMatches++;redThree=false;
    }else queryDifferences++;
  }
  if(redThree)threePositionWitnesses++;
  check(obs.context.metrics.get("discovery11.shared_order_writes")===58n&&
    obs.context.metrics.get("discovery11.drop_rounds")===46n&&
    obs.context.metrics.get("discovery11.post_stirs")===12n&&
    obs.context.metrics.get("discovery11.legacy_query_reads")===1n,
    "aggregate metrics accurate");
  writes+=obs.memoryWrites;dropRounds+=obs.dropRounds;postStirs+=obs.postStirRounds;
}
let realPairs=0;
for(const [c,t] of pairs){
  const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
  const visible=buildVisibleDrops(counts,STONES,hidden);
  verify(c,t,visible,initialBowls(counts),STONES);realPairs++;
}
check(realPairs===12&&cases===12&&writes===696,
  "12 real canonical day pairs contain 46 drop and 12 stir writes");

// 64 deterministic mutations of 46 actual drop sequence, including drop46
// separately; historical query still reads STIR_12, never freezes drop46 order.
const count=workCounts(F,F),hidden=buildHiddenDrops(count,STONES);
const baseline=buildVisibleDrops(count,STONES,hidden);
const seedBowls=initialBowls(count);
let varied=0;
for(let j=0;j<64;j++){
  const changed=[...baseline];
  changed[1]=j%2===0 ? BigInt(j*149+1) : -BigInt(j*137+3);
  changed[46]=j%3===0 ? BigInt(j*721+2) : -BigInt(j*719+11);
  verify(F+BigInt(j),F-BigInt(j),changed,seedBowls,STONES);
  varied++;
}
check(varied===64&&cases===76,"64 deliberate drop1/drop46 variations");

// Large signed inputs exercise exact bigint on real six-bowl state and all
// post-stir calculations, not just isolated permutation order.
const huge=(1n<<8192n)+193n;
const extreme=[huge,-huge,huge*huge,-huge*huge,0n,720n,1n<<16384n,-(1n<<16384n)];
let giant=0;
for(const d of extreme){
  const changed=[...baseline];
  changed[1]=d;changed[46]=-d+1n;
  const bowls=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
  verify(F-huge,F+huge,changed,bowls,STONES);
  giant++;
}
check(giant===8&&cases===84&&writes===4872&&dropRounds===3864&&
  postStirs===1008&&ledgerCells===29232&&
  queryDifferences+queryMatches===252&&queryDifferences>0&&
  threePositionWitnesses>0&&contexts.size===84,
  "84 independent full runs, 4872 shared writes, 252 historical query comparisons");

// Spy on historical adapter to prove production really invoked the original
// overwrite method 58 times rather than copying reference results.
const old=LegacySharedOrderMemoryAdapter.prototype.write;
let spyWrites=0;const seenMem=new Set<object>();
try{
  LegacySharedOrderMemoryAdapter.prototype.write=function(...args){
    spyWrites++;seenMem.add(this);
    return old.apply(this,args);
  };
  const obs=discoverLegacyOrderMemory(F,F,baseline,STONES,seedBowls);
  check(spyWrites===58&&seenMem.size===1&&obs.memoryWrites===58,
    "one real shared memory instance, original write 58 times");
}finally{LegacySharedOrderMemoryAdapter.prototype.write=old;}
console.log(`STAGE_22_DISCOVERY_11_PROPERTIES_PASS realPairs=${realPairs} varied=${varied} giant=${giant} cases=${cases} writes=${writes} drops=${dropRounds} postStirs=${postStirs} ledgerCells=${ledgerCells} queryDifferences=${queryDifferences} queryMatches=${queryMatches} redWitnesses=${threePositionWitnesses} spyWrites=${spyWrites}`);
