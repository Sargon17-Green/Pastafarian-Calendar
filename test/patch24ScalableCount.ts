import {
 ScalableLegalWeavingCounter,Discovery24FullHandler,
 Patch23FullHandler,Discovery23FullHandler,
 Patch22FullHandler,Discovery22FullHandler,Patch21CutletHandler,
 Discovery21LegacyCutletHandler,Patch20StructureSauceHandler,
 Discovery20StructureSauceHandler,Patch19YearCacheHandler,
 discoverLegacyIndependentDailyMonths
} from "../src/index.ts";
import {weavingFamily} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert}
 from "./discovery21Fixtures.ts";
let exactSmallFamilies=0,symmetricSmall=0;
for(const lengths of [
 [4n,4n,5n],[4n,5n,4n],[5n,4n,4n],
 [4n,4n,4n,4n],[4n,4n,6n],[5n,4n,5n]
]){
 const candidate=new ScalableLegalWeavingCounter(lengths);
 const expected=weavingFamily(lengths).count();
 assert(candidate.count()===expected&&candidate.count()===candidate.count(),
  "exact order-distribution count matches independent legal oracle");
 const mirrored=new ScalableLegalWeavingCounter([...lengths].reverse());
 assert(mirrored.count()===candidate.count(),
  "reverse-time/month-ID bijection preserves count");
 exactSmallFamilies++;symmetricSmall++;
}
assert(new ScalableLegalWeavingCounter([4n,4n,5n]).count()===3101n,
 "observed 3101 small exact family");
const fixture=buildStage41CompatibleLegacyFixture();
const preceding=()=>new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
  new Patch22FullHandler(new Discovery22FullHandler(
   new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
    new Patch20StructureSauceHandler(
     new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
))))))));
const full=discoverLegacyIndependentDailyMonths(preceding(),fixture.request);
const lengths=full.historical.corrected.correctedLengths;
assert(lengths.length===44&&
 lengths.reduce((sum,x)=>sum+x,0n)===5349n&&
 full.historical.context.status==="PATCH_23_APPLIED",
 "true full Stage48 chain and 5349-day source");
const large=new ScalableLegalWeavingCounter(lengths);
const largeCount=large.count();
const reverse=new ScalableLegalWeavingCounter([...lengths].reverse());
assert(largeCount===reverse.count()&&
 largeCount>(1n<<127n)&&
 large.statistics().peakDistributionCells===5350&&
 large.statistics().transitions<250000&&
 large.statistics().months===44,
 "real-year exact count via bounded one-dimensional memory and reversal");
console.log("STAGE_49_SCALABLE_LEGAL_WEAVING_COUNT_PASS"+
 " smallFamilies="+exactSmallFamilies+
 " reverseSymmetrySmall="+symmetricSmall+
 " realYearDays="+large.totalDays+" monthCount="+lengths.length+
 " realYearCountBits="+largeCount.toString(2).length+
 " productionOneDimTransitions="+large.statistics().transitions+
 " peakCells="+large.statistics().peakDistributionCells+
 " giantUnrankPending=1 stage49NotClosed=1 archivedExpectedReds=24");
