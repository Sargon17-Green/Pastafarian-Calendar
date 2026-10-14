import {
  LegacyYearNumberOnlyCache,Patch19GuardedYearNumberCache,
  Patch19YearCacheHandler,patch19GuardedYearCache,
  exactCalculationDayFingerprint,Legacy365JumpGuessAdapter,
  Patch18OneYearWalker
} from "../src/index.ts";
import {buildDiscovery19Fixture,assert} from "./discovery19Fixtures.ts";
function value(key:bigint,c:bigint,open:bigint,close:bigint){
 return Object.freeze({
  calculationDay:c,year:Object.freeze({
   number:key,openGateIndex:-3n,closeGateIndex:3n,
   openGateDay:open,closeGateDay:close
  }),source:"ACTUAL_STAGE37_YEAR_WALK" as const
 });
}
const bits=1n<<32768n;
const corrected=new Patch19GuardedYearNumberCache();
let unique=0,actionOnly=0,openingOnly=0,closingOnly=0,combined=0;
let validHits=0,missing=0,wrongOld=0;
const seen=new Set<string>();
for(let j=0;j<512;j++){
 const key=j%2===0?bits*BigInt(j+1):-bits*BigInt(j+1);
 const c=j%2===0?bits+BigInt(j)*149n:-bits-BigInt(j)*159n;
 const open=c-900n,close=c+1234n;
 const fresh=value(key,c,open,close);
 const action=value(key,c+1n,open,close);
 const changeOpening=value(key,c+1n,open-1n,close);
 const changeClosing=value(key,c+1n,open-1n,close+1n);
 const both=value(key,c+3n,open-3n,close+3n);
 const a=corrected.resolve(fresh);
 assert(a.correctedMiss&&a.oldResult===undefined&&a.oldInsertCalls===1,
  "initial historical number-only map miss");
 missing++;
 const b=corrected.resolve(fresh);
 assert(b.correctedHit&&b.fingerprintMatched&&
  b.openGateMatched&&b.closeGateMatched&&b.oldValueCoherent,
  "all three guards permit actual HIT");
 validHits++;
 const x=corrected.resolve(action);
 assert(x.correctedMiss&&!x.fingerprintMatched&&
  x.openGateMatched&&x.closeGateMatched&&x.oldWouldServeWrong&&
  x.correctedServed.calculationDay===c+1n,
  "action-only false HIT is repaired");
 actionOnly++;
 const y=corrected.resolve(changeOpening);
 assert(y.correctedMiss&&y.fingerprintMatched&&
  !y.openGateMatched&&y.closeGateMatched&&y.oldWouldServeWrong,
  "open-only false HIT is repaired");
 openingOnly++;
 const z=corrected.resolve(changeClosing);
 assert(z.correctedMiss&&z.fingerprintMatched&&
  z.openGateMatched&&!z.closeGateMatched&&z.oldWouldServeWrong,
  "close-only false HIT is repaired");
 closingOnly++;
 const all=corrected.resolve(both);
 assert(all.correctedMiss&&!all.fingerprintMatched&&
  !all.openGateMatched&&!all.closeGateMatched&&all.oldWouldServeWrong,
  "simultaneous three-fault HIT is repaired");
 combined++;
 const checkAgain=corrected.resolve(both);
 assert(checkAgain.correctedHit&&!checkAgain.oldWouldServeWrong&&
  checkAgain.correctedServed.year.openGateDay===open-3n,
  "repeat exact year returns repaired HIT");
 validHits++;
 seen.add(exactCalculationDayFingerprint(c));
 unique++;
 if(x.oldWouldServeWrong)wrongOld++;
}
const stats=corrected.inspect();
assert(unique===512&&seen.size===512&&
 actionOnly===512&&openingOnly===512&&closingOnly===512&&
 combined===512&&missing===512&&validHits===1024&&wrongOld===512&&
 stats.entries===512&&stats.hits===1024&&stats.misses===2560&&
 stats.historical.size===512&&stats.historical.reads===3584&&
 stats.historical.writes===2560&&
 stats.guards.length===512,
 "512 giant signed keys, 3584 real oldGet, all three independent failures, 1024 valid HITs");

// Cross-action real Year5000 queries with reverse history order must
// preserve Stage38 wrong behavior AND serve corrected true years.
const f=buildDiscovery19Fixture();
const handler=new Patch19YearCacheHandler();
const requests=[f.second,f.first,f.second,f.second,f.first,f.first];
let calls=0,miss=0,hit=0,historyWrong=0,correctWrong=0;
let fullPredecessors=0,fullWrites=0;
const contexts=new Set<object>();
const oldWalk=Patch18OneYearWalker.prototype.walk;
const oldGuess=Legacy365JumpGuessAdapter.prototype.oldJumpGuess;
let physicalWalks=0,ghostCalls=0;
try{
 Patch18OneYearWalker.prototype.walk=function(...args){
  physicalWalks++;return oldWalk.apply(this,args);
 };
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=function(...args){
  ghostCalls++;return oldGuess.apply(this,args);
 };
 for(let i=0;i<requests.length;i++){
  const q=requests[i]!;
  const x=patch19GuardedYearCache(handler,q);
  const desired=i===0||i===2||i===3?f.secondSeed:f.firstSeed;
  const equal=(a:typeof x.correctedServed.year,b:typeof x.correctedServed.year)=>
   a.number===b.number&&a.openGateIndex===b.openGateIndex&&
   a.closeGateIndex===b.closeGateIndex&&
   a.openGateDay===b.openGateDay&&a.closeGateDay===b.closeGateDay;
  if(x.correctedHit)hit++;else miss++;
  if(x.originalWrongHistory.oldWrongHit)historyWrong++;
  if(!equal(x.correctedServed.year,desired))correctWrong++;
  assert(equal(x.fresh.year,desired)&&equal(x.correctedServed.year,desired)&&
   x.correctedGuardsApplied&&x.cacheKeyKind==="YEAR_NUMBER_ONLY"&&
   x.originalWrongHistory.cacheKeyKind==="YEAR_NUMBER_ONLY"&&
   x.originalWrongHistory.correctedCacheGuardsApplied===false&&
   x.originalWrongHistory.context.status==="DISCOVERY_19_RECORDED"&&
   x.context.status==="PATCH_19_APPLIED"&&
   x.predecessorSharedWrites===BigInt(x.trueYearPredecessorCalls)*58n&&
   x.originalWrongHistory.preceding.authoritativeYear.openGateDay===
     desired.openGateDay&&
   !contexts.has(x.context)&&
   x.context!==x.originalWrongHistory.context&&Object.isFrozen(x),
   "real Stage37 recomputed exact Year5000 and guarded cache never altered year boundaries");
  contexts.add(x.context);
  fullPredecessors+=x.trueYearPredecessorCalls;
  fullWrites+=Number(x.predecessorSharedWrites);
  calls++;
 }
}finally{
 Patch18OneYearWalker.prototype.walk=oldWalk;
 Legacy365JumpGuessAdapter.prototype.oldJumpGuess=oldGuess;
}
const s=handler.corrected.inspect();
assert(calls===6&&physicalWalks===6&&ghostCalls===12&&
 miss===4&&hit===2&&historyWrong===3&&
 correctWrong===0&&contexts.size===6&&
 fullWrites===fullPredecessors*58&&
 s.entries===1&&s.historical.size===1&&
 s.historical.reads===6&&s.historical.writes===4&&
 s.misses===4&&s.hits===2&&
 handler.historical.legacyCache.inspect().reads===6&&
 handler.historical.legacyCache.inspect().writes===1,
 "reverse order real Year5000 still has intentionally old wrong HITs, all guarded results correct");
console.log("STAGE_39_PATCH_19_PROPERTIES_PASS directKeys="+unique+
 " fingerprintUnique="+seen.size+" cDayOnlyMiss="+actionOnly+
 " openingOnlyMiss="+openingOnly+" closingOnlyMiss="+closingOnly+
 " tripleMiss="+combined+" emptyMiss="+missing+
 " trueDirectHits="+validHits+" historicalWouldBeWrong="+wrongOld+
 " originalMapGets="+stats.historical.reads+
 " originalMapPuts="+stats.historical.writes+
 " bigIntBits=32768"+
 " realQueries="+calls+" realHITs="+hit+" realMISSes="+miss+
 " originalWrongHITs="+historyWrong+" correctedWrong="+correctWrong+
 " stage37Walks="+physicalWalks+" old365Calls="+ghostCalls+
 " realPredecessors="+fullPredecessors+
 " realWrites="+fullWrites+" correctedKeyCount="+s.entries);
