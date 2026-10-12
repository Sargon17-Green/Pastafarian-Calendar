import { discoverLegacyFixedNextBowl } from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,bowlOrderFromNumber
} from "./normativeOracle.ts";
import { canonicalNextBowl } from "./discovery12Reference.ts";
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const visible=[...buildVisibleDrops(counts,STONES,hidden)];
// Canonical DROP46 rank 2: order [1,2,3,4,6,5] असे निश्चित साक्षी.
visible[46]=2n;
const expectedOrder=bowlOrderFromNumber(2n);
if(expectedOrder.join(",")!=="1,2,3,4,6,5")throw Error("INVALID_DISCOVERY_12_ORDER_RANK");
let mismatches=0,matches=0;
for(const id of [4,5,6]){
  const old=discoverLegacyFixedNextBowl(F,F,visible,STONES,initialBowls(counts),id);
  const canonical=canonicalNextBowl(expectedOrder,id);
  if(old.orderAt46Latch.join(",")!==expectedOrder.join(",")||
    old.sharedMemoryWrites!==58||old.latchCaptures!==1||
    old.legacyNextBowlId!==old.numericSuccessorCalls*(id===6?1:id+1)){
    throw Error("INVALID_DISCOVERY_12_PROVENANCE");
  }
  console.log(`DISCOVERY_12_WITNESS queriedId=${id} legacyNumeric=${old.legacyNextBowlId} canonicalPositionSuccessor=${canonical} latch=${old.orderAt46Latch.join(",")} postStirSource=${old.preceding.historical.latestSource}`);
  if(old.legacyNextBowlId===canonical)matches++;else mismatches++;
}
if(mismatches===3&&matches===0)
  throw Error("DISCOVERY_12_EXPECTED_RED mismatches=3 matches=0 ids=4,5,6 order=1,2,3,4,6,5");
throw Error(`DISCOVERY_12_INVALID_RED mismatches=${mismatches} matches=${matches}`);
