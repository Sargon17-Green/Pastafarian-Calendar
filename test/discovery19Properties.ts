import {
  LegacyYearNumberOnlyCache,Discovery19YearNumberCacheHandler,
  discoverLegacyYearNumberCache,Legacy365JumpGuessAdapter,
  Patch18OneYearWalker
} from "../src/index.ts";
import {buildDiscovery19Fixture,assert} from "./discovery19Fixtures.ts";
function value(yearNumber:bigint,day:bigint,open:bigint,close:bigint){
 return Object.freeze({
  calculationDay:day,
  year:Object.freeze({number:yearNumber,openGateIndex:-3n,
   closeGateIndex:3n,openGateDay:open,closeGateDay:close}),
  source:"ACTUAL_STAGE37_YEAR_WALK" as const
 });
}
const huge=1n<<32768n;
const direct=new LegacyYearNumberOnlyCache();
let directKeys=0,unprotectedHits=0,staleOpen=0,staleCalc=0;
const numbers=[-huge,-1n,0n,1n,huge,5000n];
for(let j=0;j<512;j++){
 const key=j<numbers.length?numbers[j]!:BigInt(j)*huge+BigInt(j);
 const base=(j%2===0?huge:-huge)+BigInt(j)*99n;
 const first=value(key,base,base-123n,base+1000n);
 const stale=value(key,base+1n,base-234n,base+765n);
 assert(direct.oldGet(key)===undefined,"fresh key miss");
 direct.oldPut(key,first);directKeys++;
 const old=direct.oldGet(key)!;
 if(old.calculationDay!==stale.calculationDay)staleCalc++;
 if(old.year.openGateDay!==stale.year.openGateDay)staleOpen++;
 if(old!==stale&&old.calculationDay!==stale.calculationDay&&
    old.year.openGateDay!==stale.year.openGateDay)unprotectedHits++;
 assert(old.year.number===key&&old.calculationDay===base&&
  old.year.openGateDay===base-123n&&old.year.closeGateDay===base+1000n&&
  Object.isFrozen(old)&&Object.isFrozen(old.year),
  "old key-only lookup cannot observe new calculation or its changed gates");
}
const snapshot=direct.inspect();
assert(snapshot.size===512&&snapshot.reads===1024&&snapshot.writes===512&&
 directKeys===512&&unprotectedHits===512&&
 staleCalc===512&&staleOpen===512&&snapshot.keys.length===512,
 "512 distinct signed/giant year keys plus 512 stale hits with no guards");

const f=buildDiscovery19Fixture();
// Opposite insertion order must make the genuinely computed other
// Year5000 become the wrong cached answer, proving cache-history dependence.
const handler=new Discovery19YearNumberCacheHandler();
const first=discoverLegacyYearNumberCache(handler,f.second);
const second=discoverLegacyYearNumberCache(handler,f.first);
assert(first.fresh.year.number===5000n&&second.fresh.year.number===5000n&&
 first.fresh.calculationDay===f.second.calculationDay&&
 second.fresh.calculationDay===f.first.calculationDay&&
 !first.oldHit&&second.oldHit&&second.oldWrongHit&&
 second.served.calculationDay===f.second.calculationDay&&
 second.fresh.calculationDay===f.first.calculationDay&&
 (second.served.year.openGateDay!==second.fresh.year.openGateDay||
  second.served.year.closeGateDay!==second.fresh.year.closeGateDay)&&
 second.context.metrics.get("discovery19.wrong_old_hits")===1n&&
 second.preceding.authoritativeYear.openGateDay===f.firstSeed.openGateDay&&
 first.preceding.authoritativeYear.openGateDay===f.secondSeed.openGateDay,
 "reverse cache order physically changes wrong result despite true Stage37 recomputation");
let ghostSpy=0,yearWalkerSpy=0;
const oldGhost=Legacy365JumpGuessAdapter.prototype.oldJumpGuess;
const oldWalker=Patch18OneYearWalker.prototype.walk;
try{
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=function(...args){
  ghostSpy++;return oldGhost.apply(this,args);
 };
 Patch18OneYearWalker.prototype.walk=function(...args){
  yearWalkerSpy++;return oldWalker.apply(this,args);
 };
 const hit=discoverLegacyYearNumberCache(handler,f.first);
 assert(hit.oldHit&&hit.oldWrongHit&&
  hit.served.calculationDay===f.second.calculationDay&&
  yearWalkerSpy===1&&ghostSpy===2,
  "old hit still executes all true Stage37, both historical /365 ghost calls");
}finally{
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=oldGhost;
 Patch18OneYearWalker.prototype.walk=oldWalker;
}
assert(handler.legacyCache.inspect().size===1&&
 handler.legacyCache.inspect().writes===1&&
 handler.legacyCache.inspect().reads===3&&
 first.context!==second.context&&
 first.preceding!==second.preceding&&
 second.preceding.authoritative.seed.openGateDay===f.firstSeed.openGateDay&&
 second.preceding.predecessorSharedWrites===
   BigInt(second.preceding.predecessorCallCount)*58n,
 "bad cache owns one key but all production source chains remain genuine");
console.log("STAGE_38_DISCOVERY_19_PROPERTIES_PASS"+
 " directKeys="+directKeys+" directStaleHits="+unprotectedHits+
 " actionMismatches="+staleCalc+" openGateMismatches="+staleOpen+
 " bigIntBits=32768"+
 " realReverseFullWalks=3"+
 " realReverseWrongHits=2"+
 " realGateQuestionsPerWalk="+f.actualGateQuestions+
 " realTotalPredecessors="+
 (first.predecessorCallCount+second.predecessorCallCount)+
 " realTotalWrites="+
 (first.predecessorSharedWrites+second.predecessorSharedWrites)+
 " actualYearWalkSpy="+yearWalkerSpy+
 " historical365Spy="+ghostSpy+
 " cacheGuardApplied=0");
