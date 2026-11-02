import {calendarDateSpaghetti} from "../src/postStage55FinalDate.ts";
import {projectObservedStage55Date} from "../src/postStage55ObservedDate.ts";
import {createProductionPatch20Request} from "../src/postStage55ProductionRequest.ts";
import {MonsterValidationError} from "../src/monsterBase.ts";
import {cutletNameByCanonicalIndex,monthNameByCanonicalIndex} from "../src/sourceLanguageCatalog.ts";
import {NormativeOracle,sauce,askBowl,chooseRank,weavingFamily} from "./normativeOracle.ts";
import {IndependentLegalWeavingRank} from "./postStage55IndependentRank.ts";
import {
  Patch27FullHandler,Discovery27FullHandler,Patch26FullHandler,
  Discovery26FullHandler,Patch25FullHandler,Discovery25FullHandler,
  Patch24ScalableFullHandler,Discovery24FullHandler,Patch23FullHandler,
  Discovery23FullHandler,Patch22FullHandler,Discovery22FullHandler,
  Patch21CutletHandler,Discovery21LegacyCutletHandler,
  Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
  Patch19YearCacheHandler,patch27MonthMembership
} from "../src/index.ts";

// Gate D: six actual two-bigint calls, with independent gate/year/cutlet/name
// oracle. The giant legal weaving comes from the measured full Stage55 Native
// witness, NOT NormativeOracle.weavingFamily (which exceeds JS Map capacity
// for the 5,349-day Year5000 family). Stage49 independently proves weaving
// rank correctness; this test independently checks counts, indices and prefix.
function ok(value:boolean,detail:string):void {
  if(!value)throw Error("GATE_D: "+detail);
}
function fullStage55():Patch27FullHandler {
  return new Patch27FullHandler(new Discovery27FullHandler(
    new Patch26FullHandler(new Discovery26FullHandler(
      new Patch25FullHandler(new Discovery25FullHandler(
        new Patch24ScalableFullHandler(new Discovery24FullHandler(
          new Patch23FullHandler(new Discovery23FullHandler(
            new Patch22FullHandler(new Discovery22FullHandler(
              new Patch21CutletHandler(new Discovery21LegacyCutletHandler(
                new Patch20StructureSauceHandler(
                  new Discovery20StructureSauceHandler(new Patch19YearCacheHandler())
                )
              ))
            ))
          ))
        ))
      ))
    ))
  ));
}
// Exhaustive small-family equivalence is independent of production Stage49.
let smallExhaustive=0;
for(const ls of [[2n,2n,2n],[4n,4n,4n],[4n,4n,5n]]) {
  const independent=new IndependentLegalWeavingRank(ls);
  const reference=weavingFamily(ls);
  const total=reference.count();
  ok(independent.count()===total,"test-only insertion count equals brute oracle");
  for(let rank=1n;rank<=total;rank++) {
    ok(independent.rankWord(reference.unrank1(rank))===rank,
       "test-only exhaustive inverse rank differs");
    smallExhaustive++;
  }
}
ok(smallExhaustive===4407,"small exhaustive count 5+1301+3101");
const certifiedFamilies=new Set<string>();
let giantRankChecks=0;
const oracle=new NormativeOracle();
const anchorC=oracle.gateDay(1n)+1n;
const year5000=oracle.year5000(anchorC);
const next=oracle.nextYear(anchorC,year5000);
const nonAnchorC=anchorC+1n;
const nonAnchorYear=oracle.year5000(nonAnchorC);
const previous=oracle.previousYear(nonAnchorC,nonAnchorYear);
const cases=[
  {label:"same-day",c:anchorC,t:anchorC},
  {label:"year-first-day",c:anchorC,t:year5000.openGateDay+1n},
  {label:"year-last-exact-gate",c:anchorC,t:year5000.closeGateDay},
  {label:"real-year5000-day239-gap",c:anchorC,t:year5000.openGateDay+239n},
  {label:"next-year",c:anchorC,t:next.openGateDay+2n},
  {label:"non-anchor-previous-year",c:nonAnchorC,t:previous.closeGateDay-1n}
] as const;
const distinct=new Set(cases.map(p=>p.c.toString()+":"+p.t.toString()));
ok(distinct.size===6,"six distinct ordered (c,t) pairs");
let compared=0,checkedInterleavings=0,totalObservedCalls=0;
let totalObservedWrites=0n;
let gapChecked=0,exactGateChecked=0;
for(const item of cases) {
  const title=item.label;
  const year=oracle.findTargetYear(item.c,item.t);
  const referenceSauce=sauce(item.c,year.openGateDay+1n);
  const k=oracle.chooseCutletCount(referenceSauce,year);
  const cutlets=oracle.materializeCutlets(
    year,
    oracle.chooseCutletPartition(item.c,referenceSauce,year,k),
    oracle.chooseCutletNames(referenceSauce,k)
  );
  const cutlet=cutlets.find(x=>x.firstDay<=item.t&&item.t<=x.lastDay);
  ok(cutlet!==undefined,title+": independently identified cutlet");
  const monthCount=oracle.chooseMonthCount(referenceSauce,year);
  const monthLengths=oracle.chooseMonthLengths(referenceSauce,year,monthCount);
  const monthNames=oracle.chooseMonthNames(referenceSauce,monthCount);
  const request=createProductionPatch20Request(item.c,item.t);
  const native=patch27MonthMembership(fullStage55(),request,1,1);
  const observed=projectObservedStage55Date(request,native);
  const weaving=native.historical.historical.historical.historical.historical.historical.corrected.legalWeaving;
  const yearDays=Number(year.closeGateDay-year.openGateDay);
  ok(weaving.length===yearDays,title+": true year length");
  const counts=Array<number>(monthCount).fill(0);
  for(const month of weaving){
    ok(Number.isSafeInteger(month)&&month>=1&&month<=monthCount,
       title+": legal month ID bounds");
    counts[month-1]!++;
  }
  ok(counts.every((n,i)=>BigInt(n)===monthLengths[i]),
     title+": independent month-length count");
  // An independently ranked *complete* word certifies every derived prefix,
  // including month ID and ordinal on this target day. A production Native
  // word is a candidate, never the expected rank, which comes only from
  // independent Sauce/Bowl4/Seal32 and independent insertion-DP counting.
  const certificateKey=item.c.toString()+":"+year.openGateDay.toString()+
    ":"+year.closeGateDay.toString();
  if(!certifiedFamilies.has(certificateKey)) {
    const independent=new IndependentLegalWeavingRank(monthLengths);
    ok(independent.totalDays===yearDays&&monthCount<=47&&yearDays<=5778,
       title+": full-size preflight bounds");
    const exactTotal=independent.count();
    const wanted=chooseRank(askBowl(referenceSauce,4,32n),exactTotal);
    const measuredRank=independent.rankWord(weaving);
    const costs=independent.statistics();
    ok(costs.factorTerms<=6000000&&costs.suffixQueries<=300000,
       title+": bounded non-exponential rank work");
    ok(measuredRank===wanted,title+": independently ranked full legal weaving");
    certifiedFamilies.add(certificateKey);
    giantRankChecks++;
    console.log("POST_STAGE55_GATE_D_INDEPENDENT_FAMILY_PASS year="+year.number+
      " rankBits="+wanted.toString(2).length+" days="+yearDays+
      " months="+monthCount+" factorTerms="+costs.factorTerms+
      " suffixQueries="+costs.suffixQueries+" mismatches=0");
  }
  const dayIndex=Number(item.t-year.openGateDay)-1;
  ok(dayIndex>=0&&dayIndex<weaving.length,title+": bounded day index");
  const monthId=weaving[dayIndex]!;
  const ordinal=BigInt(weaving.slice(0,dayIndex+1).filter(m=>m===monthId).length);
  const expected=[
    year.number,
    cutletNameByCanonicalIndex(cutlet!.canonicalIndex),
    item.t-cutlet!.firstDay+1n,
    monthNameByCanonicalIndex(monthNames[monthId-1]!),
    ordinal
  ] as const;
  const publicDate=calendarDateSpaghetti(item.c,item.t);
  ok(publicDate.length===5&&Object.isFrozen(publicDate)&&
     Object.keys(publicDate).length===5,
     title+": exact immutable five-part public API");
  for(let i=0;i<5;i++) {
    ok(publicDate[i]===expected[i]&&observed.date[i]===expected[i],
       title+": field "+(i+1)+" differs from independent reference");
    compared++;
  }
  ok(observed.totalSharedWrites===58n*BigInt(observed.totalNativeCalls)&&
     observed.stage55AdditionalNativeQueries===0,
     title+": measured Native accounting / no extra membership query");
  totalObservedCalls+=observed.totalNativeCalls;
  totalObservedWrites+=observed.totalSharedWrites;
  for(let sample=1;sample<=39;sample++) {
    const index=Math.floor(sample*weaving.length/40);
    const id=weaving[index]!;
    const prefix=weaving.slice(0,index+1).filter(m=>m===id).length;
    ok(prefix>=1&&prefix<=counts[id-1]!,title+": bounded weaving prefix "+sample);
    checkedInterleavings++;
  }
  if(item.label==="real-year5000-day239-gap") {
    ok(year.number===5000n&&weaving[238]!==44,
       "actual Year5000 day239 is not a month44 member");
    gapChecked++;
  }
  if(item.label==="year-last-exact-gate") {
    ok(item.t===year.closeGateDay, "last day is an actual signed gate");
    exactGateChecked++;
  }
  console.log("POST_STAGE55_GATE_D_PAIR_PASS name="+title+
    " year="+year.number+" nativeCalls="+observed.totalNativeCalls+
    " sharedWrites="+observed.totalSharedWrites+" components=5");
}
let malformed=0;
const malformedPairs:readonly (readonly [unknown,unknown])[]=[
  [0,0n],[0n,0],["1",1n],[1n,"1"],
  [null,1n],[1n,undefined],[NaN,1n],[1n,false]
];
for(const [c,t] of malformedPairs){
  try{calendarDateSpaghetti(c as bigint,t as bigint);}
  catch(e){if(e instanceof MonsterValidationError)malformed++;}
}
ok(malformed===malformedPairs.length,"8 malformed public arguments rejected");
ok(compared===30&&checkedInterleavings===234&&gapChecked===1&&
   exactGateChecked===1&&totalObservedWrites===58n*BigInt(totalObservedCalls),
   "Gate D bounded acceptance invariants");
ok(certifiedFamilies.size===3&&giantRankChecks===3,
   "three distinct independently rank-certified full-year structures");
console.log("POST_STAGE55_GATE_D_INDEPENDENT_RANK_PASS pairs=6 components=30 smallExhaustive="+
  smallExhaustive+" realFamilyCertificates="+giantRankChecks+" rankMismatches=0");
console.log("POST_STAGE55_GATE_D_BOUNDED_DIFFERENTIAL_PASS pairs=6 components=30 mismatches=0"+
  " interleavingChecks="+checkedInterleavings+" malformedRejected="+malformed+
  " year5000Day239=1 exactGate=1 observedNativeCalls="+totalObservedCalls+
  " observedSharedWrites="+totalObservedWrites);
