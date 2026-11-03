import { calendarDateSpaghetti } from "../src/postStage55FinalDate.ts";
import { createProductionPatch20Request } from "../src/postStage55ProductionRequest.ts";
import { projectObservedStage55Date } from "../src/postStage55ObservedDate.ts";
import { Patch14WideChoiceDispatcher } from "../src/patch14WideChoice.ts";
import { cutletNameByCanonicalIndex,monthNameByCanonicalIndex } from "../src/sourceLanguageCatalog.ts";
import { IndependentLegalWeavingRank } from "./postStage55IndependentRank.ts";
import { NormativeOracle,FOUNDATION_DAY,sauce,askBowl,chooseRank } from "./normativeOracle.ts";
import {
  Patch27FullHandler,Discovery27FullHandler,Patch26FullHandler,
  Discovery26FullHandler,Patch25FullHandler,Discovery25FullHandler,
  Patch24ScalableFullHandler,Discovery24FullHandler,Patch23FullHandler,
  Discovery23FullHandler,Patch22FullHandler,Discovery22FullHandler,
  Patch21CutletHandler,Discovery21LegacyCutletHandler,
  Patch20StructureSauceHandler,Discovery20StructureSauceHandler,
  Patch19YearCacheHandler,patch27MonthMembership
} from "../src/index.ts";

/**
 * Post-Stage55 negative signed public API: seven distinct (c,t) pairs.
 * Neither the expected Sauce/Bowl selectors nor the independent insertion-DP
 * legal-word ranker invokes a production rank/unrank implementation.
 *
 * This is an intentionally separate bounded Native job, not Stage56.
 */
function ok(value:unknown,detail:string):asserts value {
  if(!value)throw new Error("NEGATIVE_SIGNED_API: "+detail);
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

const oracle=new NormativeOracle();
const negativeAnchorC=oracle.gateDay(-1n)+1n;
const negativeNonAnchorC=negativeAnchorC+1n;
const negativeAnchorYear=oracle.year5000(negativeAnchorC);
const anchorMiddleCandidate=negativeAnchorYear.openGateDay+
  (negativeAnchorYear.closeGateDay-negativeAnchorYear.openGateDay)/2n;
const negativeAnchorMidDay=anchorMiddleCandidate===negativeAnchorC?
  anchorMiddleCandidate+1n:anchorMiddleCandidate;
const negativeNonAnchorYear=oracle.year5000(negativeNonAnchorC);
const negativePrevious=oracle.previousYear(negativeNonAnchorC,negativeNonAnchorYear);
const negativeNext=oracle.nextYear(negativeNonAnchorC,negativeNonAnchorYear);
const foundationCrossingC=FOUNDATION_DAY+1n;
const foundationCrossingT=FOUNDATION_DAY-1n;

const cases=[
  {label:"negative-anchor-middle-day",c:negativeAnchorC,t:negativeAnchorMidDay},
  {label:"negative-anchor-year-first",c:negativeAnchorC,
    t:negativeAnchorYear.openGateDay+1n},
  {label:"negative-anchor-year-last-gate",c:negativeAnchorC,
    t:negativeAnchorYear.closeGateDay},
  {label:"negative-non-anchor-same-day",c:negativeNonAnchorC,
    t:negativeNonAnchorC},
  {label:"negative-previous-year-last-day",c:negativeNonAnchorC,
    t:negativePrevious.closeGateDay},
  {label:"negative-next-year-first-day",c:negativeNonAnchorC,
    t:negativeNext.openGateDay+1n},
  {label:"foundation-crossing-backward",c:foundationCrossingC,
    t:foundationCrossingT}
] as const;

ok(cases.length===7 &&
  new Set(cases.map(x=>x.c.toString()+":"+x.t.toString())).size===7,
  "seven distinct signed input pairs");
ok(cases.every(x=>x.c<0n&&x.t<0n),"all days are negative");
ok(negativeAnchorC-1n===oracle.gateDay(-1n) &&
   oracle.exactGateIndex(negativeAnchorC-1n)===-1n,
   "true negative Stage16 anchor is exactly -1");
ok(oracle.exactGateIndex(negativeNonAnchorC-1n)===null,
   "negative non-anchor truly is not a gate");
ok(foundationCrossingC-1n===FOUNDATION_DAY &&
   oracle.exactGateIndex(foundationCrossingC-1n)===0n,
   "foundation crossing is gate zero, which cannot be Stage16 anchor");
ok(oracle.findTargetYear(negativeAnchorC,negativeAnchorYear.openGateDay+1n).number===
      negativeAnchorYear.number &&
   oracle.findTargetYear(negativeAnchorC,negativeAnchorYear.closeGateDay).number===
      negativeAnchorYear.number &&
   oracle.findTargetYear(negativeNonAnchorC,negativePrevious.closeGateDay).number===
      negativePrevious.number &&
   oracle.findTargetYear(negativeNonAnchorC,negativeNext.openGateDay+1n).number===
      negativeNext.number,
   "independent oracle confirms exact prior/current/next boundary days");

type Family=Readonly<{
  weaving:readonly number[];
  monthLengths:readonly bigint[];
  monthNames:readonly number[];
  cutlets:ReturnType<NormativeOracle["materializeCutlets"]>;
}>;
const families=new Map<string,Family>();
const verifiedBranches=new Set<string>();
const originalDispatch=Patch14WideChoiceDispatcher.prototype.dispatch;
let nativeCalls=0, sharedWrites=0n;
let compared=0, interleavingChecks=0, rankChecks=0;
let firstPublic:Readonly<(bigint|string)[]>|null=null;
let replayInput:Readonly<{c:bigint;t:bigint}>|null=null;
function sameFive(a:readonly (bigint|string)[],b:readonly (bigint|string)[]):boolean {
  return a.length===5 && b.length===5 && a.every((value,index)=>value===b[index]);
}
function verifyBranch(
  c:bigint,t:bigint,request:ReturnType<typeof createProductionPatch20Request>
):void {
  const production=request.productionConstruction;
  ok(production!==undefined && production.source==="PRODUCTION_C_T_NATIVE_FACTORY",
     "production-owned Native request metadata");
  const question=request.historical.yearQuestion;
  const window=question.verifiedGateWindow;
  ok(window!==undefined && window.minimumDay<t && window.maximumDay>c &&
     window.byIndex.get(0n)===FOUNDATION_DAY,
     "complete signed Native gate window");
  ok(production.gateSharedWrites===58n*BigInt(production.gateNativeCalls),
     "physical prefix accounting");
  if(c===negativeAnchorC){
    ok(production.signedAnchorIndex===-1n &&
       production.anchorDiagnostics==="EXECUTED" &&
       question.anchorGateIndex===-1n &&
       production.oldAnchorCandidateCount>0 &&
       production.oldMultiCandidateCount>=2 &&
       question.oldAnchorCandidates.length>0 &&
       question.oldMultiCandidates.length>=2,
       "negative anchor must exercise real historical family");
    verifiedBranches.add("negative-anchor");
  } else if(c===negativeNonAnchorC){
    ok(production.signedAnchorIndex===null &&
       production.anchorDiagnostics==="SKIPPED_NO_REAL_STAGE16_ANCHOR" &&
       question.anchorGateIndex===null &&
       question.oldAnchorCandidates.length===0 &&
       question.oldMultiCandidates.length===0,
       "negative non-anchor cannot invent candidates");
    verifiedBranches.add("negative-non-anchor");
  } else if(c===foundationCrossingC){
    ok(production.signedAnchorIndex===null &&
       production.anchorDiagnostics==="SKIPPED_NO_REAL_STAGE16_ANCHOR" &&
       question.anchorGateIndex===null &&
       question.oldAnchorCandidates.length===0 &&
       question.oldMultiCandidates.length===0 &&
       window.minimumDay<=t && window.maximumDay>=c,
       "foundation index zero is not an admissible Stage16 anchor");
    verifiedBranches.add("foundation-crossing");
  } else {
    throw new Error("Unexpected calculation day in branch-specific probe");
  }
}

Patch14WideChoiceDispatcher.prototype.dispatch=function(
  ...args:Parameters<typeof originalDispatch>
) {
  const historical=args[0];
  const result=originalDispatch.apply(this,args);
  ok(historical.predecessorSharedMemoryWrites===58 &&
     historical.legacyShortOnlyCalls===1,
     "one actual 58-write legacy predecessor per Native dispatch");
  nativeCalls++;
  sharedWrites+=58n;
  ok(nativeCalls<=1200,"aggregate Native-call ceiling 1,200 exceeded");
  return result;
};

try {
  for(const item of cases){
    const year=oracle.findTargetYear(item.c,item.t);
    const referenceSauce=sauce(item.c,year.openGateDay+1n);
    const cutletCount=oracle.chooseCutletCount(referenceSauce,year);
    const cutlets=oracle.materializeCutlets(
      year,
      oracle.chooseCutletPartition(item.c,referenceSauce,year,cutletCount),
      oracle.chooseCutletNames(referenceSauce,cutletCount)
    );
    const monthCount=oracle.chooseMonthCount(referenceSauce,year);
    const monthLengths=oracle.chooseMonthLengths(referenceSauce,year,monthCount);
    const monthNames=oracle.chooseMonthNames(referenceSauce,monthCount);
    const key=item.c.toString()+":"+year.openGateDay.toString()+
      ":"+year.closeGateDay.toString();
    let family=families.get(key);

    if(family===undefined){
      const before=nativeCalls;
      const request=createProductionPatch20Request(item.c,item.t);
      verifyBranch(item.c,item.t,request);
      const native=patch27MonthMembership(fullStage55(),request,1,1);
      const observed=projectObservedStage55Date(request,native);
      // The physical dispatch spy covers the signed-gate prefix as well as
      // Stage55 and name selection. The Stage55 observation intentionally
      // counts only the latter two: compare like-for-like scoped totals.
      const prefix=request.productionConstruction;
      ok(prefix!==undefined,"production-owned prefix accounting required");
      const measuredDelta=nativeCalls-before;
      const expectedDelta=prefix.gateNativeCalls+observed.totalNativeCalls;
      ok(measuredDelta===expectedDelta &&
         prefix.gateSharedWrites===58n*BigInt(prefix.gateNativeCalls) &&
         observed.totalSharedWrites===58n*BigInt(observed.totalNativeCalls) &&
         sharedWrites===58n*BigInt(nativeCalls) &&
         observed.stage55AdditionalNativeQueries===0,
         item.label+": scoped physical Native accounting"+
         " measured="+measuredDelta+" prefix="+prefix.gateNativeCalls+
         " stage55AndNames="+observed.totalNativeCalls+
         " expected="+expectedDelta);

      const weaving=
        native.historical.historical.historical.historical.historical.historical
          .corrected.legalWeaving;
      const days=Number(year.closeGateDay-year.openGateDay);
      ok(days>=252 && days<=5778 && weaving.length===days &&
         monthCount>=3 && monthCount<=47,
         item.label+": exact full-year dimensions");
      const counted=Array<number>(monthCount).fill(0);
      for(const id of weaving){
        ok(Number.isSafeInteger(id)&&id>=1&&id<=monthCount,
           item.label+": legal month id range");
        counted[id-1]!++;
      }
      ok(counted.every((count,index)=>BigInt(count)===monthLengths[index]),
         item.label+": independent month lengths and actual word counts");

      const independent=new IndependentLegalWeavingRank(monthLengths);
      ok(independent.totalDays===days,"independent full-size rank dimensions");
      const wanted=chooseRank(askBowl(referenceSauce,4,32n),independent.count());
      const actualRank=independent.rankWord(weaving);
      const costs=independent.statistics();
      ok(costs.factorTerms<=6000000 && costs.suffixQueries<=300000,
         item.label+": bounded independent inverse-rank work");
      ok(actualRank===wanted,
         item.label+": real Native legal word differs from independent full-year rank");
      rankChecks++;

      for(let sample=1;sample<=39;sample++){
        const index=Math.floor(sample*days/40);
        const id=weaving[index]!;
        const ordinal=weaving.slice(0,index+1).filter(x=>x===id).length;
        ok(ordinal>=1&&ordinal<=counted[id-1]!,
           item.label+": independently ranked word has invalid prefix");
        interleavingChecks++;
      }
      family={weaving,monthLengths,monthNames,cutlets};
      families.set(key,family);
      console.log("POST_STAGE55_NEGATIVE_FAMILY_PASS name="+item.label+
        " year="+year.number+" days="+days+" months="+monthCount+
        " rankBits="+actualRank.toString(2).length+
        " factorTerms="+costs.factorTerms+
        " suffixQueries="+costs.suffixQueries+" mismatches=0");
    }else{
      ok(family.monthLengths.length===monthLengths.length &&
         family.monthLengths.every((n,i)=>n===monthLengths[i]) &&
         family.monthNames.every((n,i)=>n===monthNames[i]),
         item.label+": same calculation-year must keep normative structure");
    }

    const cutlet=family.cutlets.find(x=>x.firstDay<=item.t&&item.t<=x.lastDay);
    ok(cutlet!==undefined,item.label+": unique normative cutlet required");
    const dayIndex=Number(item.t-year.openGateDay)-1;
    ok(dayIndex>=0 && dayIndex<family.weaving.length,
       item.label+": local day offset bounds");
    const monthId=family.weaving[dayIndex]!;
    const ordinal=BigInt(family.weaving.slice(0,dayIndex+1)
      .filter(x=>x===monthId).length);
    ok(ordinal>=1n && ordinal<=family.monthLengths[monthId-1]!,
       item.label+": exact one-based month ordinal");
    const expected=[
      year.number,
      cutletNameByCanonicalIndex(cutlet.canonicalIndex),
      item.t-cutlet.firstDay+1n,
      monthNameByCanonicalIndex(family.monthNames[monthId-1]!),
      ordinal
    ] as const;

    const beforePublic=nativeCalls;
    const publicDate=calendarDateSpaghetti(item.c,item.t);
    ok(nativeCalls>beforePublic,
       item.label+": public two-bigint API must physically run Native");
    ok(publicDate.length===5 && Object.keys(publicDate).length===5 &&
       Object.isFrozen(publicDate) &&
       typeof publicDate[0]==="bigint" &&
       typeof publicDate[1]==="string" &&
       typeof publicDate[2]==="bigint" &&
       typeof publicDate[3]==="string" &&
       typeof publicDate[4]==="bigint",
       item.label+": frozen canonical five-part output");
    for(let field=0;field<5;field++){
      ok(publicDate[field]===expected[field],
         item.label+": independently expected field "+(field+1)+" mismatch");
      compared++;
    }
    if(firstPublic===null) {
      firstPublic=publicDate;
      replayInput={c:item.c,t:item.t};
    }
    console.log("POST_STAGE55_NEGATIVE_PAIR_PASS name="+item.label+
      " year="+year.number+" components=5 nativeCalls="+(nativeCalls-beforePublic));
  }

  ok(compared===35 && families.size===5 && rankChecks===5 &&
     interleavingChecks===195 && verifiedBranches.size===3,
     "exact seven-pair, five-family and three-path acceptance counters");

  ok(firstPublic!==null && replayInput!==null,
     "a public date is available for independent replay");
  const replay=calendarDateSpaghetti(replayInput.c,replayInput.t);
  ok(sameFive(firstPublic,replay) &&
     replay!==firstPublic && Object.isFrozen(replay),
     "fresh public replay must be immutable, equal and separately allocated");
  ok(sharedWrites===58n*BigInt(nativeCalls)&&nativeCalls>0,
     "all physical Native dispatches reconcile to 58 shared writes each");
  console.log("POST_STAGE55_NEGATIVE_SIGNED_API_PASS pairs="+cases.length+
    " components="+compared+" independentFamilies="+families.size+
    " rankMismatches=0 negativeAnchor=-1 negativeNonAnchor=null"+
    " foundationCrossing=1 nativeCalls="+nativeCalls+
    " sharedWrites="+sharedWrites+" interleavingChecks="+interleavingChecks);
}finally{
  Patch14WideChoiceDispatcher.prototype.dispatch=originalDispatch;
}
