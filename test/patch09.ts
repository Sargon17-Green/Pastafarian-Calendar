import {
  bootstrapMonster, createMonsterContext, LegacyFixedBowlPoursAdapter,
  LegacyBowlAliasAdapter, Patch09BowlAliasHandler, patch09Pours,
  discoverLegacyFixedPours, patch08Permutation, calendarDateSpaghetti,
  MonsterStageError, MonsterValidationError
} from "../src/index.ts";
import { FOUNDATION_DAY as F, bowlOrderFromDrop } from "./normativeOracle.ts";
import { normativeThreePours } from "./discovery09Reference.ts";
function check(ok:boolean,why:string){if(!ok)throw Error(why);}
function rejects(f:()=>unknown, Cls:typeof MonsterStageError|typeof MonsterValidationError){
  try{f();}catch(e){return e instanceof Cls;}return false;
}
const bowls=Object.freeze([101n,211n,307n,401n,503n,601n]);
const stone=Object.freeze([2n,3n,5n,7n,11n]);
const samples=[1n,2n,120n,121n,240n,359n,719n,720n] as const;
const seen=new Set<object>();
let witnesses=0,correctedCells=0,correctedMismatches=0,oldWrong=0,oldMatches=0;
const aliasAdapter=new LegacyBowlAliasAdapter();
for(const d of samples){
  const obs=patch09Pours(F,F,7,d,bowls,stone);
  const oracle=normativeThreePours(7,d,bowls,stone);
  const archival=discoverLegacyFixedPours(F,F,7,d,bowls,stone);
  const order=bowlOrderFromDrop(d);
  witnesses++;
  check(obs.order.join(",")===order.join(",") &&
    obs.order.join(",")===patch08Permutation(F,F,d).order.join(","),
    "Stage17 correct permutation is reused");
  check(obs.bowlAlias.length===7 && obs.bowlAlias[0]===0 &&
    obs.bowlAlias.slice(1).join(",")===order.join(",") &&
    obs.legacyPositionBowlView.length===6 &&
    obs.legacyPositionBowlView.every((v,k)=>v===bowls[order[k]!-1]),
    "all six positions have explicit aliases");
  for(let p=0;p<3;p++){
    correctedCells++;
    if(obs.correctedPours[p]!==oracle[p])correctedMismatches++;
    if(archival.legacyPours[p]===oracle[p])oldMatches++;else oldWrong++;
    check(obs.historicalPours[p]===archival.legacyPours[p],
      "original fixed-position historical branch must remain");
  }
  check(Object.isFrozen(obs)&&Object.isFrozen(obs.correctedPours)&&
    Object.isFrozen(obs.historicalPours)&&Object.isFrozen(obs.bowlAlias)&&
    Object.isFrozen(obs.originalBowls)&&Object.isFrozen(obs.inputStone)&&
    Object.isFrozen(obs.legacyPositionBowlView),"all outputs and snapshots frozen");
  check(!seen.has(obs.context)&&obs.context.status==="PATCH_09_APPLIED"&&
    obs.context.phase==="READY","own per-call ready context");
  seen.add(obs.context);
  check(obs.context.branchTrace.join(",")=== [
    "BOOTSTRAP_VALIDATE","PATCH_09_INSTALL_ORDER_ALIASES",
    "PATCH_09_VIRTUAL_BOWL_POSITION_READS",
    "PATCH_09_REUSE_FIXED_LEGACY_POURS_WITH_ALIASES"
  ].join(","),"three historical trace steps");
  check(obs.context.metrics.get("bootstrap.calls")===1n &&
    obs.context.metrics.get("patch09.calls")===1n &&
    obs.context.metrics.get("patch09.historical_calls")===1n &&
    obs.context.metrics.get("patch09.aliased_legacy_calls")===1n &&
    obs.context.metrics.get("patch09.position_alias_reads")===6n,
    "6 aliases and 2 real historical helper invocations");
}
check(witnesses===8&&correctedCells===24&&correctedMismatches===0&&
  oldWrong===16&&oldMatches===8,
  "archival 16 wrong and 8 accidental matches must become 24 correct");

// Instrument original historical helper; repaired path must call it with
// raw old bowls and a second time with virtual aliased view.
const original=LegacyFixedBowlPoursAdapter.prototype.legacyFixedPours;
const calls:(readonly bigint[])[]=[];
try{
  LegacyFixedBowlPoursAdapter.prototype.legacyFixedPours=function(...args){
    calls.push(args[4]);
    return original.apply(this,args);
  };
  const x=patch09Pours(F,F,7,120n,bowls,stone);
  check(calls.length===2 && calls[0]===bowls &&
    calls[1]===x.legacyPositionBowlView && calls[0]!==calls[1] &&
    x.historicalCalls===1 && x.aliasCalls===1,
    "both calls really reach the unmodified old method");
}finally{LegacyFixedBowlPoursAdapter.prototype.legacyFixedPours=original;}

// Original legacy read still wrong for reordered bowls.
const old=discoverLegacyFixedPours(F,F,7,120n,bowls,stone);
check(old.legacyPours.join(",")===
  patch09Pours(F,F,7,120n,bowls,stone).historicalPours.join(","),
  "original raw path preserved");
const order=patch08Permutation(F,F,120n).order;
const alias=aliasAdapter.installOrderAliases(order);
check(Object.isFrozen(alias)&&alias[0]===0 &&
  Array.from({length:6},(_,k)=>aliasAdapter.bowlByLegacyPosition(bowls,alias,k+1))
    .every((v,k)=>v===bowls[order[k]!-1]),
  "all 6 aliases point to correct bowl IDs");
for(const badOrder of [
  [1,2,3],[1,2,3,4,5,5],[0,1,2,3,4,5],[1,2,3,4,5,7],[1,2,3,4,5,1.5]
]){
  check(rejects(()=>aliasAdapter.installOrderAliases(badOrder),MonsterValidationError),
    "invalid permutation rejected before creating aliases");
}
for(const pos of [0,-1,7,1.5,NaN,Infinity]){
  check(rejects(()=>aliasAdapter.bowlByLegacyPosition(bowls,alias,pos),
    MonsterValidationError),"invalid position rejected");
}
check(rejects(()=>aliasAdapter.bowlByLegacyPosition([1n],alias,1),MonsterValidationError) &&
  rejects(()=>aliasAdapter.bowlByLegacyPosition(bowls,[0,1,2,3,4,5,5],1),
    MonsterValidationError),"invalid virtual bowl storage / alias rejected");

const handler=new Patch09BowlAliasHandler(),raw=createMonsterContext(F,F);
check(rejects(()=>handler.run(raw,1,1n,bowls,stone),MonsterStageError)&&
  raw.status==="NEW"&&!raw.metrics.size&&!raw.branchTrace.length,
  "unready state unchanged");
const ready=bootstrapMonster(F,F);
for(const i of [0,-1,47,1.5,NaN,Infinity,"1" as unknown as number])
  check(rejects(()=>handler.run(ready,i,1n,bowls,stone),MonsterValidationError),
    "drop index range");
for(const d of [1,"1",null,undefined,NaN] as unknown[])
  check(rejects(()=>handler.run(ready,1,d as bigint,bowls,stone),
    MonsterValidationError),"non-bigint drops rejected");
for(const b of [[1n,2n],Object.assign(new Array<bigint>(6),
  {0:1n,1:2n,3:4n,4:5n,5:6n}),
  [1n,2n,3n,4n,5n,0 as unknown as bigint]])
  check(rejects(()=>handler.run(ready,1,1n,b,stone),MonsterValidationError),
    "sparse/wrong bowls");
for(const s of [[1n,2n],Object.assign(new Array<bigint>(5),
  {0:1n,1:2n,3:4n,4:5n}),
  [1n,2n,3n,4n,5 as unknown as bigint]])
  check(rejects(()=>handler.run(ready,1,1n,bowls,s),MonsterValidationError),
    "invalid stones");
check(rejects(()=>handler.run({...ready,targetDay:null as unknown as bigint},
  1,1n,bowls,stone),MonsterValidationError),"invalid context day");
check(ready.status==="VALIDATED"&&ready.branchTrace.join(",")==="BOOTSTRAP_VALIDATE"&&
  ready.metrics.size===1,"validation preflight must not mutate context");
handler.run(ready,1,1n,bowls,stone);
check(rejects(()=>handler.run(ready,2,1n,bowls,stone),MonsterStageError),
  "reused context must fail");
const left=patch09Pours(F,F,9,120n,bowls,stone),right=patch09Pours(F,F,9,120n,bowls,stone);
left.context.metrics.set("private",42n);left.context.logs.push("पहिलाच");
check(left.context!==right.context&&left.legacyPositionBowlView!==right.legacyPositionBowlView&&
  left.correctedPours!==right.correctedPours&&!right.context.metrics.has("private")&&
  !right.context.logs.length,"per-call ownership and isolation");
check(rejects(()=>calendarDateSpaghetti(F,F),MonsterStageError),
  "final date route must remain unavailable before Stage 54");
console.log(`STAGE_19_PATCH_09_GUARDS_PASS witnesses=${witnesses} cells=${correctedCells} mismatches=${correctedMismatches} historicalWrong=${oldWrong} historicalMatches=${oldMatches} aliases=6 originalCalls=2`);
