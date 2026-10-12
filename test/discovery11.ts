import {
  bootstrapMonster,createMonsterContext,LegacySharedOrderMemoryAdapter,
  Discovery11OverwrittenOrderHandler,discoverLegacyOrderMemory,
  MonsterStageError,MonsterValidationError,calendarDateSpaghetti
} from "../src/index.ts";
import {
  FOUNDATION_DAY as F,STONES,workCounts,buildHiddenDrops,
  buildVisibleDrops,initialBowls,applyVisibleDropsToBowls,
  postStir12,sauce,bowlOrderFromDrop
} from "./normativeOracle.ts";
function check(ok:boolean,why:string):void{if(!ok)throw Error(why);}
function rejects(f:()=>unknown,Cls:typeof MonsterValidationError|typeof MonsterStageError){
  try{f();}catch(e){return e instanceof Cls;}return false;
}
function fixture(c:bigint,t:bigint){
  const count=workCounts(c,t),hidden=buildHiddenDrops(count,STONES);
  return {visible:buildVisibleDrops(count,STONES,hidden),initial:initialBowls(count)};
}
const pairs:readonly (readonly [bigint,bigint])[]=[
 [F,F],[F-1n,F],[F+1n,F],[F,F-1n],[F,F+1n],
 [F-89n,F+273n],[F+273n,F-89n],[-278522n,-278522n],
 [-278522n,-268522n],[1n,1n],[100000n,-100000n],[-100000n,100000n]
];
let tested=0,realMismatches=0,realMatches=0;
let witness:ReturnType<typeof discoverLegacyOrderMemory>|null=null;
let witnessOrder:readonly number[]|null=null;
const contexts=new Set<object>();
for(const [c,t] of pairs){
  const {visible,initial}=fixture(c,t);
  const snap=[...initial];
  const obs=discoverLegacyOrderMemory(c,t,visible,STONES,initial);
  const reference=applyVisibleDropsToBowls([...initial] as [bigint,bigint,bigint,bigint,bigint,bigint],visible,STONES);
  const expectedFinal=postStir12([...reference.bowls] as [bigint,bigint,bigint,bigint,bigint,bigint]);
  const canonical=sauce(c,t);
  tested++;
  check(obs.dropRounds===46&&obs.postStirRounds===12&&
    obs.memoryWrites===58&&obs.queryReads===1&&obs.latestSource==="STIR_12"&&
    obs.ledger.length===58,"58 writes to one overwritable order");
  check(obs.ledger[0]!.index===1&&obs.ledger[0]!.source==="DROP_1"&&
    obs.ledger[45]!.index===46&&obs.ledger[45]!.source==="DROP_46"&&
    obs.ledger[46]!.index===47&&obs.ledger[46]!.source==="STIR_1"&&
    obs.ledger[57]!.index===58&&obs.ledger[57]!.source==="STIR_12",
    "strict sequence of actual writes");
  check(obs.ledger.every((r,i)=>r.index===i+1&&r.order.length===6&&
    Object.isFrozen(r)&&Object.isFrozen(r.order)&&new Set(r.order).size===6),
    "immutable forensic ledger and valid six-item orders");
  for(let i=1;i<=46;i++){
    check(obs.ledger[i-1]!.order.join(",")===bowlOrderFromDrop(visible[i]!).join(","),
      "each real drop writes its own computed order");
  }
  check(obs.ledger[45]!.order.join(",")===reference.orderAtDrop46.join(",")&&
    obs.legacyQueryOrder.join(",")===obs.ledger[57]!.order.join(",")&&
    obs.latestOrder.join(",")===obs.legacyQueryOrder.join(",")&&
    obs.legacyQueryOrder!==obs.ledger[45]!.order,
    "legacy query reads last overwritten order, not canonical drop46 slot");
  check(obs.afterDropBowls.every((v,j)=>v===reference.bowls[j])&&
    obs.finalBowls.every((v,j)=>v===expectedFinal[j]&&v===canonical.bowls[j])&&
    reference.orderAtDrop46.join(",")===canonical.orderAtDrop46.join(","),
    "all corrected bowl calculations match independent complete normative oracle");
  check(obs.initialBowls.every((v,j)=>v===initial[j]&&v===snap[j])&&
    initial.every((v,j)=>v===snap[j])&&
    Object.isFrozen(obs)&&Object.isFrozen(obs.ledger)&&
    Object.isFrozen(obs.initialBowls)&&Object.isFrozen(obs.afterDropBowls)&&
    Object.isFrozen(obs.finalBowls)&&Object.isFrozen(obs.legacyQueryOrder),
    "caller unchanged and all returned snapshots frozen");
  check(!contexts.has(obs.context)&&obs.context.status==="DISCOVERY_11_RECORDED"&&
    obs.context.phase==="READY"&&obs.context.metrics.get("bootstrap.calls")===1n&&
    obs.context.metrics.get("discovery11.calls")===1n&&
    obs.context.metrics.get("discovery11.drop_rounds")===46n&&
    obs.context.metrics.get("discovery11.post_stirs")===12n&&
    obs.context.metrics.get("discovery11.shared_order_writes")===58n&&
    obs.context.metrics.get("discovery11.legacy_query_reads")===1n,
    "metrics and independent ready context");
  contexts.add(obs.context);
  check(obs.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE","DISCOVERY_11_46_PATCH10_BOWL_ROUNDS",
    "DISCOVERY_11_12_POST_STIR_ROUNDS","DISCOVERY_11_ONE_OVERWRITABLE_ORDER_MEMORY",
    "DISCOVERY_11_QUERY_READS_LAST_STIR"
  ].join(","),"four distinct historic processing phases");
  for(const pos of [1,2,6]){
    if(obs.legacyQueryOrder[pos-1]===reference.orderAtDrop46[pos-1])realMatches++;
    else realMismatches++;
  }
  if([1,2,6].every(pos=>obs.legacyQueryOrder[pos-1]!==reference.orderAtDrop46[pos-1])&&!witness){
    witness=obs;witnessOrder=reference.orderAtDrop46;
  }
}
check(tested===12&&contexts.size===12&&realMismatches>0&&
  realMismatches+realMatches===36&&witness!==null&&witnessOrder!==null,
  "12 canonical real-day runs and a full three-position RED witness");
const sample=witness!;
for(const pos of [1,2,6]){
  check(sample.legacyQueryOrder[pos-1]!==witnessOrder![pos-1],
    "expected-red fixed positions 1/2/6");
}
check(sample.legacyQueryOrder!==sample.ledger[57]!.order,
  "query copies mutable memory; forensic log not runtime query source");

// The original one-buffer adapter really rewrites the *same* object 58 times.
const mem=new LegacySharedOrderMemoryAdapter(),same=mem.memoryIdentity;
for(let k=1;k<=46;k++){
  mem.write("DROP_"+k,[1,2,3,4,5,6]);
  check(mem.memoryIdentity===same,"physical general memory identity unchanged");
}
for(let k=1;k<=12;k++)mem.write("STIR_"+k,[6,5,4,3,2,1]);
const beforeQuery=mem.queries;
const queried=mem.queryLegacyOrder();
const afterQuery=mem.queries;
check(mem.writes===58&&mem.latestSource==="STIR_12"&&beforeQuery===0&&
  queried.join(",")==="6,5,4,3,2,1"&&afterQuery===1,
  "query actually invokes last-value memory");
check(rejects(()=>mem.write("STIR_13",[1,2,3,4,5,6]),MonsterValidationError)&&
  rejects(()=>mem.write("DROP_47",[1,2,3,4,5,6]),MonsterValidationError)&&
  rejects(()=>mem.write("STIR_1",[1,2,3,4,5,5]),MonsterValidationError),
  "legacy memory source and rank validity checks");

const f=fixture(F,F),raw=createMonsterContext(F,F);
const handler=new Discovery11OverwrittenOrderHandler();
check(rejects(()=>handler.run(raw,f.visible,STONES,f.initial),MonsterStageError)&&
  raw.status==="NEW"&&raw.metrics.size===0&&raw.branchTrace.length===0,
  "unready context unchanged");
const ready=bootstrapMonster(F,F);
for(const vis of [[],[1n,2n],Object.assign(new Array<bigint>(47),{1:1n})]){
  check(rejects(()=>handler.run(ready,vis,STONES,f.initial),MonsterValidationError),
    "sparse/incorrect visible array");
}
for(const st of [[],STONES.slice(0,46),STONES.map((v,j)=>j===10?[1n]:v)]){
  check(rejects(()=>handler.run(ready,f.visible,st,f.initial),MonsterValidationError),
    "all 46 stone rows require five bigint elements");
}
for(const b of [[1n],[1n,2n,3n,4n,5n,0 as unknown as bigint]]){
  check(rejects(()=>handler.run(ready,f.visible,STONES,b),MonsterValidationError),
    "six valid bigint bowl inputs");
}
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},
  f.visible,STONES,f.initial),MonsterValidationError)&&
  ready.status==="VALIDATED"&&ready.metrics.size===1&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE",
  "all bad input preflights leave context unchanged");
handler.run(ready,f.visible,STONES,f.initial);
check(rejects(()=>handler.run(ready,f.visible,STONES,f.initial),MonsterStageError),
  "context cannot be reused");

// Failure injection after DROP46 and during 12 post-stirs; no external partial commit.
let injected=0;
for(const at of [1,46,47,52,58]){
  const ctx=bootstrapMonster(F,F),input=[...f.initial];let invoked=0;
  const broken=new Discovery11OverwrittenOrderHandler(n=>{
    invoked++;if(n===at)throw new Error("INJECTED_11_FAILURE");
  });
  try{broken.run(ctx,f.visible,STONES,input);throw Error("no fault!");}
  catch(e){check(e instanceof Error&&e.message==="INJECTED_11_FAILURE","original fault propagated");}
  check(invoked===at&&ctx.status==="VALIDATED"&&ctx.metrics.size===1&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
    input.every((v,j)=>v===f.initial[j]),"no partially committed context or caller bowls");
  const retry=handler.run(ctx,f.visible,STONES,input);
  check(retry.memoryWrites===58&&retry.latestSource==="STIR_12",
    "deterministic retry success after interruption");
  injected++;
}
check(injected===5,"five fault boundaries tested");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "final calendar still unavailable before Stage 54");
console.log(`STAGE_22_DISCOVERY_11_GUARDS_PASS pairs=${tested} writesPerPair=58 rounds=46 postStirs=12 mismatches=${realMismatches} matches=${realMatches} redPositions=1,2,6 witness=1 injectedFailures=${injected}`);
