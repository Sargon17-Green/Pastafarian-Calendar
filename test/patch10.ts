import {
  bootstrapMonster,createMonsterContext,Patch10SnapshotStirHandler,
  Patch10ShadowBowlAdapter,patch10Stir,discoverLegacyInPlaceStir,
  LegacyInPlaceBowlStirAdapter,patch09Pours,calendarDateSpaghetti,
  MonsterValidationError,MonsterStageError
} from "../src/index.ts";
import { FOUNDATION_DAY as F,bowlOrderFromDrop } from "./normativeOracle.ts";
import { normativeSingleStir } from "./discovery10Reference.ts";
function check(ok:boolean,msg:string):void{if(!ok)throw Error(msg)}
function rejects(f:()=>unknown,Cls:typeof MonsterValidationError|typeof MonsterStageError){
  try{f()}catch(e){return e instanceof Cls}return false;
}
const b=Object.freeze([101n,211n,307n,401n,503n,601n]);
const stone=Object.freeze([2n,3n,5n,7n,11n]);
const witnesses=[-1n,0n,1n,2n,120n,121n,719n,720n] as const;
const contexts=new Set<object>();
let cases=0,cells=0,mismatches=0,historicalWrong=0,historicalMatches=0;
for(const d of witnesses){
  const obs=patch10Stir(F,F,7,d,b,stone);
  const norm=normativeSingleStir(7,d,b,stone);
  const historical=discoverLegacyInPlaceStir(F,F,7,d,b,stone);
  cases++;
  check(obs.dropIndex===7&&obs.dropValue===d&&
    obs.order.join(",")===bowlOrderFromDrop(d).join(",")&&
    obs.order.join(",")===norm.order.join(",")&&
    obs.pour.slice(0,3).join(",")===patch09Pours(F,F,7,d,b,stone).correctedPours.join(","),
    "Stage 17/19 corrected permutation and pour reused");
  check(obs.correctedSteps.length===6&&obs.historicalSteps.length===6&&
    obs.historicalReadContaminations===6&&obs.oldMethodCalls===1&&
    obs.stagedWrites===6&&obs.committedWrites===6,
    "1 real historical helper, 6 staged values, 6 explicit committed values");
  check(Object.isFrozen(obs)&&Object.isFrozen(obs.correctedSteps)&&
    Object.isFrozen(obs.historicalSteps)&&Object.isFrozen(obs.correctedBowls)&&
    Object.isFrozen(obs.originalBowls)&&Object.isFrozen(obs.vaultOld)&&
    Object.isFrozen(obs.pending)&&Object.isFrozen(obs.inputStone)&&
    Object.isFrozen(obs.historicalBowls)&&
    obs.correctedSteps.every(step=>Object.isFrozen(step)),
    "all observable snapshots immutable");
  check(obs.vaultOld!==obs.pending&&obs.pending!==obs.correctedBowls&&
    obs.vaultOld!==obs.originalBowls&&obs.originalBowls!==b&&
    obs.originalBowls.every((v,j)=>v===b[j])&&
    obs.vaultOld.every((v,j)=>v===b[j])&&
    obs.pending.every((v,j)=>v===obs.correctedBowls[j]),
    "vaultOld preserved and pending committed only when all six complete");
  check(!contexts.has(obs.context),"per-call context unique");contexts.add(obs.context);
  check(obs.context.status==="PATCH_10_APPLIED"&&obs.context.phase==="READY"&&
    obs.context.branchTrace.join(",")==[
      "BOOTSTRAP_VALIDATE","PATCH_10_VAULT_OLD_CLONE","PATCH_10_PENDING_CLONE",
      "PATCH_10_ALL_READS_FROM_VAULT_OLD","PATCH_10_SIX_PENDING_WRITES",
      "PATCH_10_FINAL_SIX_BOWL_COMMIT"
    ].join(",")&&
    obs.context.metrics.get("bootstrap.calls")===1n&&
    obs.context.metrics.get("patch10.calls")===1n&&
    obs.context.metrics.get("patch10.real_legacy_shadow_calls")===1n&&
    obs.context.metrics.get("patch10.vaultOld_clones")===1n&&
    obs.context.metrics.get("patch10.pending_clones")===1n&&
    obs.context.metrics.get("patch10.vaultOld_step_reads")===6n&&
    obs.context.metrics.get("patch10.pending_writes")===6n&&
    obs.context.metrics.get("patch10.final_commit_writes")===6n&&
    obs.context.metrics.get("patch10.historical_overwritten_reads")===6n,
    "distinct vault, pending, commit events & metrics");
  for(let position=1;position<=6;position++){
    const step=obs.correctedSteps[position-1]!;
    const bowlId=obs.order[position-1]!;
    const prevId=obs.order[(position+4)%6]!;
    const nextId=obs.order[position%6]!;
    check(step.position===position&&step.bowlId===bowlId&&
      step.previousId===prevId&&step.nextId===nextId&&
      step.currentRead===b[bowlId-1]&&
      step.previousRead===b[prevId-1]&&
      step.nextRead===b[nextId-1]&&
      step.stagedValue===obs.pending[bowlId-1]&&
      step.stagedValue===norm.expectedSteps[position-1],
      "every value read from original vault and staged exactly");
    cells++;
    if(obs.correctedBowls[bowlId-1]!==norm.expectedBowls[bowlId-1])mismatches++;
    if(historical.legacyBowls[bowlId-1]===norm.expectedBowls[bowlId-1])historicalMatches++;
    else historicalWrong++;
  }
  check(obs.historicalBowls.join(",")===historical.legacyBowls.join(",")&&
    obs.historicalSteps.every((s,j)=>
      s.newlyWrittenValue===historical.steps[j]!.newlyWrittenValue),
    "actual historical scar retained independently");
}
check(cases===8&&cells===48&&mismatches===0&&historicalWrong===40&&historicalMatches===8,
  "8 witnesses, zero corrected differences; historical scar 40/8 unchanged");

// Real historical legacy helper is called once for shadow evidence, never as
// corrected implementation; no fake result or historical rewrite.
const orig=LegacyInPlaceBowlStirAdapter.prototype.stirInPlace;
const seenOld:(bigint[])[]=[];
try{
  LegacyInPlaceBowlStirAdapter.prototype.stirInPlace=function(...args){
    seenOld.push(args[7]);
    return orig.apply(this,args);
  };
  const obs=patch10Stir(F,F,7,120n,b,stone);
  check(seenOld.length===1&&seenOld[0]!==b&&
    seenOld[0]!.join(",")===obs.historicalBowls.join(",")&&
    obs.correctedBowls.join(",")!==obs.historicalBowls.join(","),
    "real old method call isolated, corrected branch not using it");
}finally{LegacyInPlaceBowlStirAdapter.prototype.stirInPlace=orig;}

const shadow=new Patch10ShadowBowlAdapter();
const pour=Object.freeze([...patch09Pours(F,F,7,120n,b,stone).correctedPours,0n,0n,0n]);
const order=bowlOrderFromDrop(120n);
const prepared=shadow.stage(F,F,7,120n,b,stone,order,pour);
check(prepared.vaultOld!==prepared.pending&&
  prepared.vaultOld.join(",")===b.join(",")&&
  prepared.steps.length===6&&Object.isFrozen(prepared)&&
  Object.isFrozen(prepared.pending)&&Object.isFrozen(prepared.vaultOld),
  "staged six writes before any commit");
const owned=[...b];
const committed=shadow.commit(owned,prepared);
check(owned.join(",")===committed.join(",")&&
  owned.join(",")===prepared.pending.join(",")&&
  committed.every((v,j)=>v===normativeSingleStir(7,120n,b,stone).expectedBowls[j])&&
  b.join(",")==="101,211,307,401,503,601",
  "explicit final commit changes only owned working array");
check(rejects(()=>shadow.commit([1n,2n,3n,4n,5n,6n],prepared),
  MonsterValidationError),"commit rejects a destination mismatching the vault");
for(const invalid of [[1,2,3],[1,2,3,4,5,5],[1,2,3,4,5,7]]){
  check(rejects(()=>shadow.stage(F,F,7,120n,b,stone,invalid,pour),
    MonsterValidationError),"invalid order rejected");
}

const unready=createMonsterContext(F,F);
const handler=new Patch10SnapshotStirHandler();
check(rejects(()=>handler.run(unready,7,120n,b,stone),MonsterStageError)&&
  unready.status==="NEW"&&!unready.branchTrace.length&&!unready.metrics.size,
  "invalid lifecycle must not mutate state");
const ready=bootstrapMonster(F,F);
for(const i of [0,-1,47,1.5,NaN,Infinity,"1" as unknown as number])
  check(rejects(()=>handler.run(ready,i,120n,b,stone),MonsterValidationError),"invalid ordinal");
for(const d of [1,"1",null,undefined,NaN] as unknown[])
  check(rejects(()=>handler.run(ready,7,d as bigint,b,stone),MonsterValidationError),
    "nonbigint drop");
for(const arr of [[1n],[1n,2n,3n,4n,5n],
  Object.assign(new Array<bigint>(6),{0:1n,1:2n,3:4n,4:5n,5:6n}),
  [1n,2n,3n,4n,5n,1 as unknown as bigint]]){
  check(rejects(()=>handler.run(ready,7,120n,arr,stone),MonsterValidationError),
    "invalid or sparse bowls");
}
for(const arr of [[1n],[1n,2n,3n,4n],
  Object.assign(new Array<bigint>(5),{0:1n,1:2n,3:4n,4:5n}),
  [1n,2n,3n,4n,1 as unknown as bigint]]){
  check(rejects(()=>handler.run(ready,7,120n,b,arr),MonsterValidationError),
    "invalid or sparse stone");
}
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},7,120n,b,stone),
  MonsterValidationError)&&ready.status==="VALIDATED"&&
  ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ready.metrics.size===1,
  "preflight errors must not modify ready context");
handler.run(ready,7,120n,b,stone);
check(rejects(()=>handler.run(ready,7,120n,b,stone),MonsterStageError),
  "used context rejected");

// Six distinct fault injection points before final commit: not even the
// supplied context, let alone the caller's bowls, may be modified.
let injected=0;
for(let pos=1;pos<=6;pos++){
  const ctx=bootstrapMonster(F,F);
  const snapshot=[...b];
  let invoked=0;
  const crashing=new Patch10SnapshotStirHandler(position=>{
    invoked++;
    if(position===pos)throw new Error("INJECTED_STAGE_10_FAILURE");
  });
  try{crashing.run(ctx,7,120n,snapshot,stone);
    throw Error("injection did not stop stage");
  }catch(e){
    check(e instanceof Error&&e.message==="INJECTED_STAGE_10_FAILURE",
      "fault propagated unchanged");
  }
  check(invoked===pos&&ctx.status==="VALIDATED"&&
    ctx.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&ctx.metrics.size===1&&
    snapshot.every((v,j)=>v===b[j]),"no partial external mutations at any step");
  // A failed context remains valid for a subsequent deterministic call.
  const recovered=new Patch10SnapshotStirHandler().run(ctx,7,120n,snapshot,stone);
  check(recovered.correctedBowls.every((v,j)=>v===prepared.pending[j]),
    "failure recovery yields same six results");
  injected++;
}
check(injected===6,"all six before-commit fault boundaries");

const left=patch10Stir(F,F,7,120n,b,stone),right=patch10Stir(F,F,7,120n,b,stone);
left.context.logs.push("पहिला");left.context.metrics.set("private",1n);
check(left.context!==right.context&&
  left.vaultOld!==right.vaultOld&&left.pending!==right.pending&&
  left.correctedSteps!==right.correctedSteps&&
  left.correctedBowls.join(",")===right.correctedBowls.join(",")&&
  !right.context.logs.length&&!right.context.metrics.has("private"),
  "reentrant calls have isolated state");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "full calendar route still unavailable before Stage54");
console.log(`STAGE_21_PATCH_10_GUARDS_PASS witnesses=${cases} cells=${cells} mismatches=${mismatches} historicWrong=${historicalWrong} historicMatches=${historicalMatches} vaultReads=6 pendingWrites=6 committedWrites=6 injectedFailures=${injected} legacyCalls=1`);
