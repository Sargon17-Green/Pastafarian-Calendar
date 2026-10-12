import { Patch12PermutationSuccessorAdapter,LegacyNextBowlFixedNameAdapter,
 patch12NextBowl } from "../src/index.ts";
import { FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,buildVisibleDrops,
 initialBowls,applyVisibleDropsToBowls,postStir12,bowlOrderFromNumber,bowlOrderFromDrop
} from "./normativeOracle.ts";
import { canonicalNextBowl } from "./discovery12Reference.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
const fixed=new Patch12PermutationSuccessorAdapter(),legacy=new LegacyNextBowlFixedNameAdapter();
let orders=0,cells=0,mismatches=0,oldWrong=0,oldMatches=0;
let numericWrap=0,positionWrap=0,positionWrapOldWrong=0;
const unique=new Set<string>();
for(let rank=1n;rank<=720n;rank++){
 const order=bowlOrderFromNumber(rank);unique.add(order.join(","));orders++;
 const last=order[5]!;
 check(fixed.nextFromLatchedPermutation(order,last)===order[0],
 "last cyclic position wraps to first");positionWrap++;
 if(legacy.oldNextBowlFixedName(last)!==order[0])positionWrapOldWrong++;
 check(legacy.oldNextBowlFixedName(6)===1,"old numeric ID6 wraps");numericWrap++;
 for(let id=1;id<=6;id++){
  const want=canonicalNextBowl(order,id),actual=fixed.nextFromLatchedPermutation(order,id);
  if(actual!==want)mismatches++;
  if(legacy.oldNextBowlFixedName(id)===want)oldMatches++;else oldWrong++;
  check(actual!==id&&order.includes(actual),"next position contains other ID");cells++;
 }
}
check(orders===720&&unique.size===720&&cells===4320&&mismatches===0&&
 oldWrong===3456&&oldMatches===864&&numericWrap===720&&
 positionWrap===720&&positionWrapOldWrong===576,
 "full 720×6 corrected grid and unchanged numeric historical scar");
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let histories=0,sharedWrites=0,real=0,varied=0,giant=0,ranks=0;
let fullWrong=0,fullOldWrong=0,fullOldSame=0;
const contexts=new Set<object>(),observedRanks=new Set<string>();
function verify(c:bigint,t:bigint,visible:readonly bigint[],start:readonly bigint[],
 queriedId:number,kind:"real"|"varied"|"giant"|"rank"):void{
 const snapshot=[...start];
 const out=patch12NextBowl(c,t,visible,STONES,start,queriedId);
 const expectedOrder=bowlOrderFromDrop(visible[46]!);
 const want=canonicalNextBowl(expectedOrder,queriedId);
 const oracle=applyVisibleDropsToBowls(
  [...start] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
 const final=postStir12(
  [...oracle.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
 if(out.correctedNextBowlId!==want)fullWrong++;
 if(out.legacyNextBowlId!==want)fullOldWrong++;else fullOldSame++;
 histories++;sharedWrites+=out.sharedMemoryWrites;
 check(out.orderAt46Latch.join(",")===expectedOrder.join(",")&&
   out.actualDrop46Order.join(",")===oracle.orderAtDrop46.join(",")&&
   out.preceding.sharedMemoryWrites===58&&out.preceding.historical.memoryWrites===58&&
   out.preceding.historical.latestSource==="STIR_12"&&
   out.preceding.ledger[45]!.source==="DROP_46"&&
   out.preceding.ledger[57]!.source==="STIR_12"&&
   out.preceding.ledger.length===58&&
   out.afterDropBowls.every((v,j)=>v===oracle.bowls[j])&&
   out.finalBowls.every((v,j)=>v===final[j])&&
   start.every((v,j)=>v===snapshot[j])&&
   out.sharedMemoryWrites===58&&out.latchCaptures===1&&
   out.numericSuccessorCalls===1&&out.positionalSuccessorCalls===1&&
   out.context.status==="PATCH_12_APPLIED"&&
   out.context.metrics.get("patch12.legacy_numeric_calls")===1n&&
   out.context.metrics.get("patch12.corrected_positional_calls")===1n&&
   Object.isFrozen(out.orderAt46Latch)&&Object.isFrozen(out)&&
   !contexts.has(out.context),"full runtime chain and immutable owner");
 contexts.add(out.context);
 if(kind==="rank")observedRanks.add(out.orderAt46Latch.join(","));
}
for(const [c,t] of pairs){
 const counts=workCounts(c,t),hidden=buildHiddenDrops(counts,STONES);
 verify(c,t,buildVisibleDrops(counts,STONES,hidden),initialBowls(counts),
  (real%6)+1,"real");real++;
}
const counts=workCounts(F,F),hidden=buildHiddenDrops(counts,STONES);
const baseline=buildVisibleDrops(counts,STONES,hidden),start=initialBowls(counts);
for(let j=0;j<64;j++){
 const changed=[...baseline];
 changed[1]=j%2===0?BigInt(j*149+1):-BigInt(j*137+3);
 changed[46]=j%3===0?BigInt(j*721+2):-BigInt(j*719+11);
 verify(F+BigInt(j),F-BigInt(j),changed,start,(j%6)+1,"varied");varied++;
}
const huge=(1n<<8192n)+193n;
for(const d of [huge,-huge,huge*huge,-huge*huge,0n,720n,
 1n<<16384n,-(1n<<16384n)]){
 const changed=[...baseline];changed[1]=d;changed[46]=-d+1n;
 const bowls=[huge+11n,-huge-13n,huge+17n,-huge-23n,huge+37n,-huge-41n];
 verify(F-huge,F+huge,changed,bowls,(giant%6)+1,"giant");giant++;
}
for(let rank=1n;rank<=720n;rank++){
 const changed=[...baseline];changed[46]=rank;
 verify(F,F,changed,start,(Number(rank)%6)+1,"rank");ranks++;
}
check(real===12&&varied===64&&giant===8&&ranks===720&&histories===804&&
 sharedWrites===46632&&contexts.size===804&&observedRanks.size===720&&
 fullWrong===0&&fullOldWrong>0&&fullOldSame>0&&
 fullOldWrong+fullOldSame===histories,
 "804 full histories and 58 writes each, fixed next and preserved old wrong");
console.log("STAGE_25_PATCH_12_PROPERTIES_PASS orders="+orders+" cells="+cells+
 " mismatches="+mismatches+" oldWrong="+oldWrong+" oldMatches="+oldMatches+
 " numericWrap="+numericWrap+" positionWrap="+positionWrap+
 " positionWrapOldWrong="+positionWrapOldWrong+" realPairs="+real+
 " varied="+varied+" giant="+giant+" ranks="+ranks+
 " unique="+observedRanks.size+" histories="+histories+
 " sharedWrites="+sharedWrites+" fullMismatches="+fullWrong+
 " fullOldWrong="+fullOldWrong+" fullOldMatches="+fullOldSame);
