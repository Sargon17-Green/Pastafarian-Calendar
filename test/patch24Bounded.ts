import {
 DPUnrankLegalWeaving,LegalWeavingCapacityError,
 Discovery24LegacySelector,Patch24WeavingSelector,
 Patch24FullHandler,Discovery24FullHandler,Patch23FullHandler,
 Discovery23FullHandler,Patch22FullHandler,Discovery22FullHandler,
 Patch21CutletHandler,Discovery21LegacyCutletHandler,
 Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
 Patch19YearCacheHandler,bootstrapMonster
} from "../src/index.ts";
import {
 weavingFamily,askBowl,chooseRank,sauce
} from "./normativeOracle.ts";
import {buildStage41CompatibleLegacyFixture,assert} from "./discovery21Fixtures.ts";
let rows=0,families=0;
for(const lengths of [
 [4n,4n,4n],[4n,4n,5n],[4n,5n,4n],[5n,4n,4n],
 [4n,4n,6n],[4n,5n,5n],[4n,4n,4n,4n]
]){
 const virtual=new DPUnrankLegalWeaving(lengths,50000);
 const reference=weavingFamily(lengths);
 const n=reference.count();
 assert(virtual.count()===n&&n>0n,"लहान family exact legal weaving count");
 for(let rank=1n;rank<=n;rank++){
  assert(virtual.itemAt1(rank).join(",")===reference.unrank1(rank).join(","),
   "सर्व लहान rank वर अचूक स्वतंत्र normative lex");
  rows++;
 }
 families++;
}
const fixture=buildStage41CompatibleLegacyFixture();
const c=fixture.cDay,src=fixture.request.firstDaySauceQuestion!;
const len=[4n,4n,5n];
const old=new Discovery24LegacySelector().select(c,src,len);
const selection=new Patch24WeavingSelector(50000).select(c,src,old);
const reference=weavingFamily(len);
const n=reference.count();
const rank=chooseRank(askBowl(sauce(c,src.targetDay),4,32n),n);
assert(!old.audit.legal&&selection.exactLegalFamilySize===n&&
 selection.correctedRank===rank&&
 selection.selectedLegalWeaving.join(",")===reference.unrank1(rank).join(",")&&
 selection.trueIndependentNativeSeal32.familySize===n&&
 selection.trueIndependentNativeSeal32.predecessorSharedWrites===58&&
 selection.trueIndependentNativeSeal32.seal===32n&&
 selection.historicalGhostActuallyExecuted&&!selection.oldGhostReused,
 "जुना ghost खऱ्या Seal32 मुळे अलग, correct legal rank दुसऱ्या Native प्रश्नावर");
const preceding=()=>new Discovery24FullHandler(
 new Patch23FullHandler(new Discovery23FullHandler(
  new Patch22FullHandler(new Discovery22FullHandler(
   new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
    new Patch20StructureSauceHandler(
     new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
))))))));
const ctx=bootstrapMonster(c,fixture.request.historical.yearQuestion.targetDay);
let exactBlock:LegalWeavingCapacityError|null=null;
try{new Patch24FullHandler(preceding(),
 new Patch24WeavingSelector(6000)).run(ctx,fixture.request);}
catch(e){if(e instanceof LegalWeavingCapacityError)exactBlock=e;else throw e;}
assert(exactBlock!==null&&
 exactBlock.yearDays===5349&&exactBlock.monthCount===44&&
 exactBlock.exploredStates>=6000&&
 ctx.status==="VALIDATED"&&
 ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ctx.metrics.size===1,
 "वास्तविक Year5000 वर bounded DP खुल्या अपयशासह; caller rollback");
console.log("STAGE_49_PATCH_24_BOUNDED_PROTOTYPE_PASS"+
 " exhaustiveSmallRows="+rows+" smallFamilies="+families+
 " correctSmallNativeSeal32=1 archivedGhostExecuted=1"+
 " realYearDays="+exactBlock.yearDays+" realMonthCount="+exactBlock.monthCount+
 " measuredCapacityStates="+exactBlock.exploredStates+
 " stateLimit="+exactBlock.stateLimit+
 " honestUnresolvedRealYear=1 stage49NotClosed=1");
