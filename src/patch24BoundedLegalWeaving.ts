import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
 Discovery24FullHandler,discoverLegacyIndependentDailyMonths,
 LegacyIndependentDailyMonthChooser,auditLegacyWeaving
} from "./discovery24LegacyDailyMonths.ts";
import type {
 Discovery24FullObservation,Discovery24LegacyObservation
} from "./discovery24LegacyDailyMonths.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// PATCH24 चे संशोधनात्मक, मर्यादित exact backend.
// ५३४९-दिवसांचा निकाल मिळाल्याशिवाय Stage49 पूर्ण नाही.
export class LegalWeavingCapacityError extends MonsterStageError {
 readonly exploredStates:number;readonly stateLimit:number;
 readonly yearDays:number;readonly monthCount:number;
 constructor(explored:number,limit:number,days:number,m:number) {
  super("अचूक legal-weaving DP ची जाहीर स्मृतीमर्यादा गाठली");
  this.name="LegalWeavingCapacityError";
  this.exploredStates=explored;this.stateLimit=limit;
  this.yearDays=days;this.monthCount=m;
 }
}
type WeaveFrame={
 remaining:number[];opened:number;closed:number;
 key:string;next:number;sum:bigint;
};
export class DPUnrankLegalWeaving {
 readonly originalLengths:readonly number[];
 readonly totalDays:number;readonly stateLimit:number;
 private readonly memo=new Map<string,bigint>();
 private total:bigint|null=null;
 private explored=0;
 constructor(lengths:readonly bigint[],stateLimit=12000) {
  if(!Array.isArray(lengths)||lengths.length<3||lengths.length>47||
     lengths.some(x=>typeof x!=="bigint"||x<4n||x>123n)||
     !Number.isSafeInteger(stateLimit)||stateLimit<100||stateLimit>200000)
   throw new MonsterValidationError("३..४७ महिने, ४..१२३ दिवस, नेमकी DP मर्यादा आवश्यक");
  this.originalLengths=Object.freeze(lengths.map(x=>Number(x)));
  this.totalDays=this.originalLengths.reduce((a,b)=>a+b,0);
  if(this.totalDays>5778)
   throw new MonsterValidationError("वर्ष जास्तीत जास्त ५७७८ दिवस");
  this.stateLimit=stateLimit;
 }
 private key(rem:readonly number[],opened:number,closed:number):string {
  return opened+":"+closed+":"+rem.join(",");
 }
 private move(rem:readonly number[],opened:number,closed:number,id:number):
  {rem:number[];opened:number;closed:number}|null {
  const i=id-1;
  const amount=rem[i]??0;
  if(amount===0)return null;
  const first=amount===this.originalLengths[i];
  if(first&&id!==opened+1)return null;
  const last=amount===1;
  if(last&&id!==closed+1)return null;
  const next=[...rem];
  next[i]=amount-1;
  return {rem:next,opened:first?id:opened,closed:last?id:closed};
 }
 private countFrom(rem:readonly number[],opened:number,closed:number):bigint {
  if(rem.every(x=>x===0))return 1n;
  const initialKey=this.key(rem,opened,closed);
  const known=this.memo.get(initialKey);
  if(known!==undefined)return known;
  const stack:WeaveFrame[]=[{
   remaining:[...rem],opened,closed,key:initialKey,next:1,sum:0n
  }];
  while(stack.length){
   if(this.memo.size+stack.length>this.stateLimit)
    throw new LegalWeavingCapacityError(
      this.memo.size+stack.length,this.stateLimit,this.totalDays,this.originalLengths.length);
   const top=stack[stack.length-1]!;
   if(top.next>this.originalLengths.length){
    const result=top.sum;
    this.memo.set(top.key,result);this.explored++;
    stack.pop();
    if(stack.length)stack[stack.length-1]!.sum+=result;
    else return result;
    continue;
   }
   const j=top.next++;
   const move=this.move(top.remaining,top.opened,top.closed,j);
   if(!move)continue;
   if(move.rem.every(x=>x===0)){top.sum+=1n;continue;}
   const key=this.key(move.rem,move.opened,move.closed);
   const cached=this.memo.get(key);
   if(cached!==undefined){top.sum+=cached;continue;}
   stack.push({remaining:move.rem,opened:move.opened,closed:move.closed,
    key,next:1,sum:0n});
  }
  throw new MonsterStageError("DP शजवणीतील अंतर्गत traversal अपयश");
 }
 count():bigint{
  if(this.total===null)
   this.total=this.countFrom(this.originalLengths,0,0);
  if(this.total<1n)throw new MonsterStageError("legal weaving कुटुंब रिकामे");
  return this.total;
 }
 itemAt1(rank:bigint):readonly number[] {
  const total=this.count();
  if(typeof rank!=="bigint"||rank<1n||rank>total)
   throw new MonsterValidationError("legal weaving 1-based rank अवैध");
  let rem=[...this.originalLengths],opened=0,closed=0,r=rank;
  const out:number[]=[];
  for(let day=0;day<this.totalDays;day++){
   let chosen=false;
   for(let j=1;j<=rem.length;j++){
    const m=this.move(rem,opened,closed,j);
    if(!m)continue;
    const block=this.countFrom(m.rem,m.opened,m.closed);
    if(r>block){r-=block;continue;}
    out.push(j);rem=m.rem;opened=m.opened;closed=m.closed;
    chosen=true;break;
   }
   if(!chosen)throw new MonsterStageError("legal weaving lex block सापडला नाही");
  }
  if(r!==1n||closed!==this.originalLengths.length||
     opened!==this.originalLengths.length)
   throw new MonsterStageError("legal weaving पूर्णतेचा पुरावा गहाळ");
  return Object.freeze(out);
 }
 statistics():Readonly<{cachedStates:number;exploredStates:number;stateLimit:number}>{
  return Object.freeze({cachedStates:this.memo.size,
   exploredStates:this.explored,stateLimit:this.stateLimit});
 }
}
export type Patch24WeavingSelection=Readonly<{
 historical:Discovery24LegacyObservation;
 exactLegalFamilySize:bigint;correctedRank:bigint;
 selectedLegalWeaving:readonly number[];oldGhostReused:boolean;
 trueIndependentNativeSeal32:Patch14WideChoiceObservation;
 historicalGhostActuallyExecuted:true;additionalNativeSauceCalls:1;
}>;
export class Patch24WeavingSelector {
 readonly stateLimit:number;
 constructor(stateLimit=12000){this.stateLimit=stateLimit;}
 select(c:bigint,firstDayQuestion:Patch18Question,
  historical:Discovery24LegacyObservation):Patch24WeavingSelection {
  if(typeof c!=="bigint"||!firstDayQuestion||
    typeof firstDayQuestion.targetDay!=="bigint"||
    !Array.isArray(firstDayQuestion.visible)||
    !Array.isArray(firstDayQuestion.stones)||
    !Array.isArray(firstDayQuestion.startBowls)||
    !historical||historical.historicalAlgorithm!=="legacyChooseEachDaySeparately"||
    historical.historicalMonthIdChoice.seal!==32n||
    historical.historicalMonthIdChoice.queriedBowlId!==4||
    historical.historicalMonthIdChoice.predecessorSharedWrites!==58||
    historical.historicalMonthIdChoice.context.calculationDay!==c||
    historical.historicalMonthIdChoice.context.targetDay!==firstDayQuestion.targetDay)
   throw new MonsterValidationError("पूर्ण जुन्या Bowl4/Seal32 ghost ची नोंद आवश्यक");
  const oldExpected=new LegacyIndependentDailyMonthChooser()
   .legacyChooseEachDaySeparately(
     historical.lengths,historical.historicalMonthIdChoice.correctedRank);
  if(oldExpected.join(",")!==historical.ghost.join(",")||
     historical.historicalDailyDecisions!==historical.ghost.length||
     historical.audit.legal!==auditLegacyWeaving(
       historical.lengths,historical.ghost).legal)
   throw new MonsterStageError("Stage48 ghost पुनर्तपासणीत वेगळा");
  const family=new DPUnrankLegalWeaving(historical.lengths,this.stateLimit);
  // हे मोठ्या वास्तविक वर्षात explicit bounded error देऊ शकते.
  const N=family.count();
  const corrected=patch14WideChoice(c,firstDayQuestion.targetDay,
    firstDayQuestion.visible,firstDayQuestion.stones,firstDayQuestion.startBowls,
    4,32n,N);
  if(corrected.queriedBowlId!==4||corrected.seal!==32n||
     corrected.familySize!==N||corrected.predecessorSharedWrites!==58)
   throw new MonsterStageError("अचूक N वर स्वतंत्र full native Seal32 आवश्यक");
  const valid=family.itemAt1(corrected.correctedRank);
  const identical=historical.audit.legal&&
    historical.ghost.length===valid.length&&
    historical.ghost.every((j,i)=>j===valid[i]);
  return Object.freeze({
   historical,exactLegalFamilySize:N,correctedRank:corrected.correctedRank,
   selectedLegalWeaving:identical?historical.ghost:valid,
   oldGhostReused:identical,trueIndependentNativeSeal32:corrected,
   historicalGhostActuallyExecuted:true as const,
   additionalNativeSauceCalls:1 as const
  });
 }
}
export type Patch24FullObservation=Readonly<{
 historical:Discovery24FullObservation;corrected:Patch24WeavingSelection;
 actualPredecessorCalls:number;actualSharedWrites:bigint;
 source:"FULL_STAGE48_PATCH24_CORRECT_LEGAL_WEAVING";context:MonsterContext;
}>;
export class Patch24FullHandler {
 readonly preceding:Discovery24FullHandler;
 private readonly selector:Patch24WeavingSelector;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery24FullHandler,
  selector:Patch24WeavingSelector=new Patch24WeavingSelector()){
  this.preceding=preceding;this.selector=selector;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch24FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
     q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("PATCH24 साठी वैध READY owner आवश्यक");
  const old=discoverLegacyIndependentDailyMonths(this.preceding,q);
  if(old.context.status!=="DISCOVERY_24_RECORDED"||
     old.weaving.actualNativeSeal32Calls!==1||
     old.historical.corrected.correctedNativeSeal31.predecessorSharedWrites!==58)
   throw new MonsterStageError("संपूर्ण Stage48 जुनी ghost साखळी आवश्यक");
  const first=old.historical.historical.historical.historical.historical.historical.preceding.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
    (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==first)
   throw new MonsterValidationError("खऱ्या वर्षाचा first-day Sauce आवश्यक");
  const corrected=this.selector.select(ctx.calculationDay,source,old.weaving);
  const calls=old.realPredecessorCalls+1;
  const result=Object.freeze({
   historical:old,corrected,
   actualPredecessorCalls:calls,actualSharedWrites:BigInt(calls)*58n,
   source:"FULL_STAGE48_PATCH24_CORRECT_LEGAL_WEAVING" as const,
   context:ctx
  });
  ctx.branchTrace.push("PATCH_24_ACTUAL_FULL_DISCOVERY24_LEGACY_GHOST");
  ctx.branchTrace.push("PATCH_24_EXACT_MEMOIZED_LEGAL_WEAVING_COUNT");
  ctx.branchTrace.push("PATCH_24_REAL_BOWL4_SEAL32_CORRECT_COUNT");
  ctx.branchTrace.push(corrected.oldGhostReused?
   "PATCH_24_REUSE_GHOST_ONLY_IDENTICAL":"PATCH_24_REPLACE_WRONG_GHOST");
  this.metrics.bump(ctx,"patch24.calls");
  this.metrics.bump(ctx,"patch24.real_corrected_seal32");
  ctx.metrics.set("patch24.native_58_write_sequences",BigInt(calls));
  ctx.metrics.set("patch24.exact_legal_family_size",corrected.exactLegalFamilySize);
  ctx.status="PATCH_24_APPLIED";
  return result;
 }
}
export function patch24LegalWeaving(handler:Patch24FullHandler,
 q:Patch20StructureRequest):Patch24FullObservation {
 if(!(handler instanceof Patch24FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH24 handler आणि प्रश्न आवश्यक");
 const yr=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(yr.calculationDay,yr.targetDay),q);
}
