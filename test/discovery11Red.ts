import { discoverLegacyOrderMemory } from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls } from "./normativeOracle.ts";

// अकरावा deliberately-red proof: positions 1,2,6 या तीन ठोस reads
// हा ऐतिहासिक code STIR_12 मधून घेतो, नियमाधारित DROP_46 मधून नाही.
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let found=false,mismatches=0,matches=0;
for(const [c,t] of pairs){
  const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
  const visible=buildVisibleDrops(counts,STONES,hidden);
  const initial=initialBowls(counts);
  const old=discoverLegacyOrderMemory(c,t,visible,STONES,initial);
  const oracle=applyVisibleDropsToBowls([...initial] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
  if(![1,2,6].every(p=>old.legacyQueryOrder[p-1]!==oracle.orderAtDrop46[p-1])){
    continue;
  }
  if(old.memoryWrites!==58||old.latestSource!=="STIR_12"||
     old.ledger[45]!.source!=="DROP_46"||
     old.ledger[57]!.source!=="STIR_12"||
     old.legacyQueryOrder.join(",")!==old.ledger[57]!.order.join(",")){
    throw new Error("DISCOVERY_11_INVALID_RED wrong memory source");
  }
  for(const p of [1,2,6]){
    const actual=old.legacyQueryOrder[p-1]!;
    const expected=oracle.orderAtDrop46[p-1]!;
    console.log(`DISCOVERY_11_WITNESS c=${c} t=${t} position=${p} legacySource=STIR_12 actual=${actual} expectedSource=DROP_46 expected=${expected} writes=${old.memoryWrites}`);
    if(actual===expected)matches++;else mismatches++;
  }
  found=true;
  break;
}
if(found&&mismatches===3&&matches===0)
  throw new Error("DISCOVERY_11_EXPECTED_RED mismatches=3 matches=0 positions=1,2,6 writes=58");
throw new Error(`DISCOVERY_11_INVALID_RED found=${found} mismatches=${mismatches} matches=${matches}`);
