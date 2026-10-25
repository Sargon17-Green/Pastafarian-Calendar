import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {
 Discovery23FullHandler,discoverLegacyMonthLengthList
} from "./discovery23LegacyMonthLengthList.ts";
import type {
 Discovery23FullObservation,Discovery23MonthLengthObservation
} from "./discovery23LegacyMonthLengthList.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// PATCH23: जुना सर्व-रांगा materialization मार्ग खरोखर जतन केला आहे.
// ही नवी स्वतंत्र आभासी यादी exact BigInt DP ने मोजते; जुने API बदलत नाही.
export class VirtualLegacyList {
 readonly L:bigint;
 readonly m:number;
 readonly lower:4;
 readonly upper:123;
 private readonly suffix:readonly (readonly bigint[])[];
 private readonly exactCount:bigint;
 constructor(L:bigint,m:number){
  if(typeof L!=="bigint"||!Number.isSafeInteger(m)||m<3||m>47||
     L<4n*BigInt(m)||L>123n*BigInt(m))
   throw new MonsterValidationError("4..123 आणि 3..47 मर्यादेतील महिन्यांची रचना आवश्यक");
  this.L=L;this.m=m;this.lower=4;this.upper=123;
  const total=Number(L);
  const rows:bigint[][]=[];
  const zero=Array<bigint>(total+1).fill(0n);
  zero[0]=1n;
  rows.push(Object.freeze(zero.slice()) as bigint[]);
  for(let remaining=1;remaining<=m;remaining++){
   const previous=rows[remaining-1]!;
   const row=Array<bigint>(total+1).fill(0n);
   let window=0n;
   for(let sum=0;sum<=total;sum++){
    if(sum>=4)window+=previous[sum-4]!;
    if(sum>=124)window-=previous[sum-124]!;
    row[sum]=window;
   }
   rows.push(Object.freeze(row) as bigint[]);
  }
  this.suffix=Object.freeze(rows);
  this.exactCount=this.suffix[m]![total]!;
  if(this.exactCount<1n)
   throw new MonsterStageError("महिन्यांच्या आभासी यादीची संख्या शून्य");
 }
 count():bigint{return this.exactCount;}
 itemAt1(rank:bigint):readonly bigint[]{
  if(typeof rank!=="bigint"||rank<1n||rank>this.exactCount)
   throw new MonsterValidationError("आभासी 1-based lex rank अवैध");
  let remaining=Number(this.L);
  let r=rank;
  const out:bigint[]=[];
  for(let position=0;position<this.m;position++){
   const suffixSlots=this.m-position-1;
   let chosen=-1;
   const low=Math.max(4,remaining-123*suffixSlots);
   const high=Math.min(123,remaining-4*suffixSlots);
   for(let x=low;x<=high;x++){
    const block=this.suffix[suffixSlots]![remaining-x]??0n;
    if(r>block)r-=block;
    else {chosen=x;remaining-=x;out.push(BigInt(x));break;}
   }
   if(chosen<0)throw new MonsterStageError("आभासी सूचीचा lex क्रम विसंगत");
  }
  if(remaining!==0||r!==1n||out.length!==this.m||
     out.some(x=>x<4n||x>123n))
   throw new MonsterStageError("आभासी रचना अपूर्ण");
  return Object.freeze(out);
 }
}
export type Patch23MonthLengthSelection=Readonly<{
 historical:Discovery23MonthLengthObservation;
 virtualFamily:VirtualLegacyList;
 correctFamilySize:bigint;
 correctedRank:bigint;
 calculatedCorrectLengths:readonly bigint[];
 correctedLengths:readonly bigint[];
 legacyEqualsCorrect:boolean;
 historicalResultReused:boolean;
 oldMaterializationActuallyAttempted:true;
 correctedNativeSeal31:Patch14WideChoiceObservation;
 additionalNativeSauceCalls:1;
}>;
export class Patch23MonthLengthSelector{
 private readonly families=new Map<string,VirtualLegacyList>();
 private getFamily(L:bigint,m:number):VirtualLegacyList{
  const key=L.toString()+":"+m;
  const prior=this.families.get(key);
  if(prior)return prior;
  if(this.families.size>=16)this.families.clear();
  const family=new VirtualLegacyList(L,m);
  this.families.set(key,family);
  return family;
 }
 select(c:bigint,source:Patch18Question,
  old:Discovery23MonthLengthObservation):Patch23MonthLengthSelection{
  if(typeof c!=="bigint"||!source||
     typeof source.targetDay!=="bigint"||
     !Array.isArray(source.visible)||!Array.isArray(source.stones)||
     !Array.isArray(source.startBowls)||!old||
     !old.historicalListAttempted||!old.historicalPhysicalEnumeration||
     old.monthCountChoice.seal!==30n||
     old.monthCountChoice.queriedBowlId!==3||
     old.monthCountChoice.predecessorSharedWrites!==58||
     old.monthCountChoice.context.calculationDay!==c||
     old.monthCountChoice.context.targetDay!==source.targetDay)
   throw new MonsterValidationError("खरी Stage46 ऐतिहासिक month-count व यादीची नोंद आवश्यक");
  if(old.listBlocked!==(old.originalRows===null)||
     (old.listBlocked&&old.historicalMonthLengthChoice!==null)||
     (!old.listBlocked&&old.historicalMonthLengthChoice===null))
   throw new MonsterStageError("Stage46 जुना materialization पुरावा विसंगत");
  const virtual=this.getFamily(old.L,old.selectedMonthCount);
  const N=virtual.count();
  const selected=patch14WideChoice(c,source.targetDay,
   source.visible,source.stones,source.startBowls,3,31n,N);
  if(selected.predecessorSharedWrites!==58||
     selected.queriedBowlId!==3||selected.seal!==31n||
     selected.familySize!==N)
   throw new MonsterStageError("PATCH23 स्वतंत्र पूर्ण Bowl3 seal31 प्रश्न हवा");
  const calculated=virtual.itemAt1(selected.correctedRank);
  const oldRows=old.historicalChosenLengths;
  const equal=oldRows!==null&&oldRows.length===calculated.length&&
   oldRows.every((v,i)=>v===calculated[i]);
  const output=equal?oldRows:calculated;
  if(output.length!==old.selectedMonthCount||
     output.reduce((s,v)=>s+v,0n)!==old.L)
   throw new MonsterStageError("PATCH23 दुरुस्त महिन्यांची रचना अवैध");
  return Object.freeze({
   historical:old,virtualFamily:virtual,
   correctFamilySize:N,correctedRank:selected.correctedRank,
   calculatedCorrectLengths:calculated,correctedLengths:output,
   legacyEqualsCorrect:equal,historicalResultReused:equal,
   oldMaterializationActuallyAttempted:true as const,
   correctedNativeSeal31:selected,
   additionalNativeSauceCalls:1 as const
  });
 }
}
export type Patch23FullObservation=Readonly<{
 historical:Discovery23FullObservation;
 corrected:Patch23MonthLengthSelection;
 actualPredecessorCalls:number;
 actualSharedWrites:bigint;
 source:"FULL_STAGE46_PATCH23_VIRTUAL_MONTH_LENGTHS";
 context:MonsterContext;
}>;
export class Patch23FullHandler{
 readonly preceding:Discovery23FullHandler;
 private readonly selector:Patch23MonthLengthSelector;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Discovery23FullHandler,
  selector:Patch23MonthLengthSelector=new Patch23MonthLengthSelector()){
  this.preceding=preceding;this.selector=selector;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Patch23FullObservation{
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
     !q?.historical?.yearQuestion||
     q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
     q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("PATCH23 साठी वैध READY owner आवश्यक");
  // पूर्वसंच संपूर्ण स्वतंत्र context मध्ये; late fault caller ला स्पर्श नाही.
  const previous=discoverLegacyMonthLengthList(this.preceding,q);
  if(previous.context.status!=="DISCOVERY_23_RECORDED"||
     previous.months.monthCountChoice.predecessorSharedWrites!==58)
   throw new MonsterStageError("पूर्ण Stage46 ऐतिहासिक predecessor आवश्यक");
  const stage41=previous.historical.historical.historical.historical.preceding;
  const first=stage41.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
   (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==first)
   throw new MonsterValidationError("वर्षाच्या पहिल्या दिवसाचा खरा Sauce हवा");
  const corrected=this.selector.select(ctx.calculationDay,source,previous.months);
  const calls=previous.realPredecessorCalls+1;
  const out=Object.freeze({
   historical:previous,corrected,
   actualPredecessorCalls:calls,actualSharedWrites:BigInt(calls)*58n,
   source:"FULL_STAGE46_PATCH23_VIRTUAL_MONTH_LENGTHS" as const,
   context:ctx
  });
  ctx.branchTrace.push("PATCH_23_CALL_ACTUAL_STAGE46_OLD_MONTH_LIST");
  ctx.branchTrace.push("PATCH_23_VIRTUAL_DP_COUNT_EXACT_BIGINT");
  ctx.branchTrace.push("PATCH_23_ACTUAL_BOWL3_SEAL31_ON_VIRTUAL_COUNT");
  ctx.branchTrace.push(corrected.historicalResultReused?
   "PATCH_23_REUSE_ONLY_IDENTICAL_LEGACY":"PATCH_23_REPLACE_BLOCKED_OR_WRONG_LEGACY");
  this.metrics.bump(ctx,"patch23.calls");
  this.metrics.bump(ctx,"patch23.corrected_seal31");
  this.metrics.bump(ctx,corrected.historicalResultReused?
   "patch23.legacy_equal":"patch23.virtual_selected");
  ctx.metrics.set("patch23.native_58_write_sequences",BigInt(calls));
  ctx.metrics.set("patch23.virtual_family_size",corrected.correctFamilySize);
  ctx.status="PATCH_23_APPLIED";
  return out;
 }
}
export function patch23MonthLengths(handler:Patch23FullHandler,
 q:Patch20StructureRequest):Patch23FullObservation{
 if(!(handler instanceof Patch23FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("PATCH23 handler आणि प्रश्न आवश्यक");
 const a=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(a.calculationDay,a.targetDay),q);
}
