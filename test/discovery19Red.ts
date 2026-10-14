// Stage38's nineteenth deliberately RED full-predecessor witness.
// Real signed gates, real Year5000(c) in two action days and real old Map key.
import {
 LegacyYearNumberOnlyCache,Discovery19YearNumberCacheHandler,
 discoverLegacyYearNumberCache
} from "../src/index.ts";
import {buildDiscovery19Fixture} from "./discovery19Fixtures.ts";
const f=buildDiscovery19Fixture();
const cache=new LegacyYearNumberOnlyCache();
const handler=new Discovery19YearNumberCacheHandler(cache);
const previous=discoverLegacyYearNumberCache(handler,f.first);
const next=discoverLegacyYearNumberCache(handler,f.second);
if(!previous.oldHit&&next.oldHit&&next.oldWrongHit&&
 next.yearNumber===5000n&&previous.yearNumber===5000n&&
 next.fresh.calculationDay===f.second.calculationDay&&
 next.served.calculationDay===f.first.calculationDay&&
 (next.served.year.openGateDay!==next.fresh.year.openGateDay||
  next.served.year.closeGateDay!==next.fresh.year.closeGateDay)&&
 next.preceding.authoritativeYear.openGateDay===f.secondSeed.openGateDay&&
 next.preceding.authoritative.gateProvenance===
   "PHYSICALLY_RECOMPUTED_SIGNED_GATES"&&
 next.predecessorSharedWrites===BigInt(next.predecessorCallCount)*58n&&
 cache.inspect().size===1&&cache.inspect().writes===1)
 throw Error("DISCOVERY_19_EXPECTED_RED wrongHits=1 matches=0 oldCacheKey=year.number year=5000 actionGuard=absent");
throw Error("DISCOVERY_19_WITNESS_DRIFT oldHit="+next.oldHit+
 " wrongHit="+next.oldWrongHit+" number="+next.yearNumber);
