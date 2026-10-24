import {
 BaseMetricsManager,bootstrapMonster,MonsterStageError,MonsterValidationError
} from "./monsterBase.ts";
import type {MonsterContext} from "./monsterBase.ts";
import {Patch22FullHandler,patch22CutletNames} from "./patch22DistinctCutletNames.ts";
import type {Patch22FullObservation} from "./patch22DistinctCutletNames.ts";
import type {Patch20StructureRequest} from "./patch20StructureSauce.ts";
import type {Patch18Question} from "./patch18YearWalk.ts";
import {patch14WideChoice} from "./patch14WideChoice.ts";
import type {Patch14WideChoiceObservation} from "./patch14WideChoice.ts";

// DISCOVERY23: मूळ API सर्व bounded positive month-length ways RAM मध्ये
// प्रत्यक्ष मांडतो. Stage47 चे virtual count/itemAt1 येथे आणू नका.
export class LegacyMonthListLimit extends MonsterStageError {
 readonly lowerBound:bigint;
 readonly minimallyRequiredBytes:bigint;
 readonly observedRows:number;
 constructor(lowerBound:bigint,minBytes:bigint,observedRows:number) {
  super("मूळ सर्व-महिने यादी सुरक्षित मर्यादेपेक्षा मोठी");
  this.name="LegacyMonthListLimit";
  this.lowerBound=lowerBound;
  this.minimallyRequiredBytes=minBytes;
  this.observedRows=observedRows;
 }
}
export class LegacyAllMonthLengthWays {
 readonly maxRows:number;
 constructor(maxRows=4096){
  if(!Number.isSafeInteger(maxRows)||maxRows<1||maxRows>100000)
   throw new MonsterValidationError("जुन्या यादीची सुरक्षित मर्यादा आवश्यक");
  this.maxRows=maxRows;
 }
 validate(L:bigint,m:number):void{
  if(typeof L!=="bigint"||!Number.isSafeInteger(m)||
   m<3||m>47||L<4n*BigInt(m)||L>123n*BigInt(m))
   throw new MonsterValidationError("महिन्यांचे 4..123 दिवस आणि 3..47 मोजणी हवी");
 }
 // बांधील लांबींचे स्वतंत्र परस्पर-संतुलित जोडपे: कोणताही DP नाही.
 // प्रत्येक जोडी (q,q) साठी (q+d,q-d) चे 2A+1 वैध पर्याय.
 // या स्वतंत्र कुटुंबांचा गुणाकार हा प्रत्यक्ष संख्येचा LOWER bound आहे.
 demonstrableLowerBound(L:bigint,m:number):bigint{
  this.validate(L,m);
  const q=Number(L/BigInt(m)),r=Number(L%BigInt(m));
  const counts:[number,number][]=[[q,m-r],[q+1,r]];
  let lower=1n;
  for(const [v,n] of counts){
   if(n<2)continue;
   const A=Math.max(0,Math.min(v-4,123-v));
   lower*=BigInt(2*A+1)**BigInt(Math.floor(n/2));
  }
  return lower;
 }
 oldAllWays(L:bigint,m:number):readonly (readonly bigint[])[] {
  this.validate(L,m);
  const lower=this.demonstrableLowerBound(L,m);
  const minBytes=lower*BigInt(8*m);
  if(lower>BigInt(this.maxRows))
   throw new LegacyMonthListLimit(lower,minBytes,0);
  const rows:(readonly bigint[])[]=[];
  const path:bigint[]=[];
  const walk=(left:bigint,remaining:number):void=>{
   if(remaining===0){
    if(left!==0n)return;
    if(rows.length>=this.maxRows)
     throw new LegacyMonthListLimit(lower,minBytes,rows.length+1);
    rows.push(Object.freeze([...path]));
    return;
   }
   const lo=left-123n*BigInt(remaining-1)>4n?
    left-123n*BigInt(remaining-1):4n;
   const hi=left-4n*BigInt(remaining-1)<123n?
    left-4n*BigInt(remaining-1):123n;
   for(let x=lo;x<=hi;x++){
    path.push(x);
    walk(left-x,remaining-1);
    path.pop();
   }
  };
  walk(L,m);
  if(rows.length===0)throw new MonsterStageError("जुन्या महिन्यांची यादी रिकामी");
  return Object.freeze(rows);
 }
}
export type Discovery23MonthLengthObservation=Readonly<{
 L:bigint;minMonths:number;maxMonths:number;selectedMonthCount:number;
 monthCountChoice:Patch14WideChoiceObservation;
 historicalListAttempted:true;historicalPhysicalEnumeration:true;
 safeMaxRows:number;demonstrableLowerBound:bigint;
 lowerBoundBytes:bigint;listBlocked:boolean;
 originalRows:readonly (readonly bigint[])[]|null;
 historicalMonthLengthChoice:Patch14WideChoiceObservation|null;
 historicalChosenLengths:readonly bigint[]|null;
 oldSeal31ActualCalls:0|1;additionalNativeSauceCalls:1|2;
 blockReason:"PREFLIGHT_LOWER_BOUND"|"ENUMERATION_LIMIT"|null;
}>;
export class Discovery23MonthLengthSelector{
 readonly old:LegacyAllMonthLengthWays;
 constructor(old:LegacyAllMonthLengthWays=new LegacyAllMonthLengthWays()){this.old=old;}
 select(c:bigint,source:Patch18Question,L:bigint):Discovery23MonthLengthObservation{
  if(typeof c!=="bigint"||!source||
   typeof source.targetDay!=="bigint"||!Array.isArray(source.visible)||
   !Array.isArray(source.stones)||!Array.isArray(source.startBowls))
   throw new MonsterValidationError("खरे वर्षाचे पहिल्या दिवसाचे Sauce आवश्यक");
  if(typeof L!=="bigint"||L<252n||L>5778n)
   throw new MonsterValidationError("वर्ष कालावधी 252..5778 हवा");
  const min=Number((L+122n)/123n);
  const max=Math.min(47,Number(L/4n));
  if(min<3||min>max)throw new MonsterStageError("महिने 3..47 मध्ये नाहीत");
  const countChoice=patch14WideChoice(c,source.targetDay,
   source.visible,source.stones,source.startBowls,3,30n,
   BigInt(max-min+1));
  if(countChoice.queriedBowlId!==3||countChoice.seal!==30n||
    countChoice.predecessorSharedWrites!==58)
   throw new MonsterStageError("खरा Bowl3 seal30 पूर्ववर्ती आवश्यक");
  const m=min+Number(countChoice.correctedRank-1n);
  const lower=this.old.demonstrableLowerBound(L,m);
  let rows:readonly (readonly bigint[])[]|null=null;
  let reason:"PREFLIGHT_LOWER_BOUND"|"ENUMERATION_LIMIT"|null=null;
  try{rows=this.old.oldAllWays(L,m);}
  catch(e){
   if(!(e instanceof LegacyMonthListLimit))throw e;
   reason=e.observedRows===0?"PREFLIGHT_LOWER_BOUND":"ENUMERATION_LIMIT";
  }
  // मोठ्या यादीवर Stage47 चे DP/virtual fix नाही. खोटे rank देऊ नये.
  const lengthChoice=rows?patch14WideChoice(c,source.targetDay,
   source.visible,source.stones,source.startBowls,3,31n,
   BigInt(rows.length)):null;
  if(lengthChoice&&(lengthChoice.queriedBowlId!==3||
     lengthChoice.seal!==31n||
     lengthChoice.predecessorSharedWrites!==58))
   throw new MonsterStageError("मूळ Bowl3 seal31 चा पूर्ण 58-write मार्ग हवा");
  const chosen=rows&&lengthChoice?
   rows[Number(lengthChoice.correctedRank-1n)]??null:null;
  if(rows&&(!chosen||chosen.length!==m||
     chosen.reduce((a,b)=>a+b,0n)!==L))
   throw new MonsterStageError("जुनी materialized lex निवड अपूर्ण");
  return Object.freeze({
   L,minMonths:min,maxMonths:max,selectedMonthCount:m,
   monthCountChoice:countChoice,
   historicalListAttempted:true as const,
   historicalPhysicalEnumeration:true as const,
   safeMaxRows:this.old.maxRows,
   demonstrableLowerBound:lower,
   lowerBoundBytes:lower*BigInt(m*8),
   listBlocked:rows===null,originalRows:rows,
   historicalMonthLengthChoice:lengthChoice,
   historicalChosenLengths:chosen,
   oldSeal31ActualCalls:rows?1 as const:0 as const,
   additionalNativeSauceCalls:rows?2 as const:1 as const,
   blockReason:reason
  });
 }
}
export type Discovery23FullObservation=Readonly<{
 historical:Patch22FullObservation;
 months:Discovery23MonthLengthObservation;
 realPredecessorCalls:number;realSharedWrites:bigint;
 context:MonsterContext;source:"FULL_STAGE45_LEGACY_MONTH_LENGTH_LIST";
}>;
export class Discovery23FullHandler {
 readonly preceding:Patch22FullHandler;
 private readonly monthSelector:Discovery23MonthLengthSelector;
 private readonly metrics=new BaseMetricsManager();
 constructor(preceding:Patch22FullHandler,
  selector:Discovery23MonthLengthSelector=new Discovery23MonthLengthSelector()){
  this.preceding=preceding;this.monthSelector=selector;
 }
 run(ctx:MonsterContext,q:Patch20StructureRequest):Discovery23FullObservation {
  if(ctx.phase!=="READY"||ctx.status!=="VALIDATED"||
    !q?.historical?.yearQuestion||
    q.historical.yearQuestion.calculationDay!==ctx.calculationDay||
    q.historical.yearQuestion.targetDay!==ctx.targetDay)
   throw new MonsterStageError("DISCOVERY23 साठी READY owner आवश्यक");
  const previous=patch22CutletNames(this.preceding,q);
  if(previous.context.status!=="PATCH_22_APPLIED"||
    previous.corrected.correctedNativeSeal22.predecessorSharedWrites!==58)
   throw new MonsterStageError("पूर्ण Stage45 इतिहास आवश्यक");
  const stage41=previous.historical.historical.historical.preceding;
  const year=stage41.historical;
  const L=year.yearCloseGateDay-year.yearOpenGateDay;
  const first=stage41.trueYearFirstDay;
  const source=q.firstDaySauceQuestion??
   (first===ctx.targetDay?q.historical.originalSauceQuestion:undefined);
  if(!source||source.targetDay!==first)
   throw new MonsterValidationError("खऱ्या वर्षाचा first-day Sauce source आवश्यक");
  const month=this.monthSelector.select(ctx.calculationDay,source,L);
  const calls=previous.actualPredecessorCalls+month.additionalNativeSauceCalls;
  const out=Object.freeze({
   historical:previous,months:month,realPredecessorCalls:calls,
   realSharedWrites:BigInt(calls)*58n,
   context:ctx,
   source:"FULL_STAGE45_LEGACY_MONTH_LENGTH_LIST" as const
  });
  ctx.branchTrace.push("DISCOVERY_23_REAL_FULL_STAGE45_PREDECESSOR");
  ctx.branchTrace.push("DISCOVERY_23_NATIVE_BOWL3_SEAL30_MONTH_COUNT");
  ctx.branchTrace.push("DISCOVERY_23_ACTUAL_OLD_ALL_MONTH_LENGTH_WAYS");
  ctx.branchTrace.push(month.listBlocked?
   "DISCOVERY_23_LEGACY_LIST_RESOURCE_BLOCKED_EXPECTED":
   "DISCOVERY_23_ORIGINAL_LIST_NATIVE_SEAL31");
  this.metrics.bump(ctx,"discovery23.calls");
  this.metrics.bump(ctx,"discovery23.old_all_list_calls");
  ctx.metrics.set("discovery23.lower_bound",month.demonstrableLowerBound);
  ctx.metrics.set("discovery23.old_list_blocked",month.listBlocked?1n:0n);
  ctx.metrics.set("discovery23.predecessor_58_write_sequences",BigInt(calls));
  ctx.status="DISCOVERY_23_RECORDED";
  return out;
 }
}
export function discoverLegacyMonthLengthList(handler:Discovery23FullHandler,
 q:Patch20StructureRequest):Discovery23FullObservation {
 if(!(handler instanceof Discovery23FullHandler)||!q?.historical?.yearQuestion)
  throw new MonsterValidationError("DISCOVERY23 handler आणि प्रश्न आवश्यक");
 const a=q.historical.yearQuestion;
 return handler.run(bootstrapMonster(a.calculationDay,a.targetDay),q);
}
