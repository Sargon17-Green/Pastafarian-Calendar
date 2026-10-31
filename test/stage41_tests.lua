-- Stage41 PATCH20: 1-based ordinal correction with all Stage40 historical scars.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local cmp=B.compare
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return out
end
O.resetGateCache()
local gates={}
for k=-8,8 do
 gates[k+9]={index=k,day=tostring(O.ensureGateIndex(k))}
end
local exact,interior=0,0
local function verify(day,records,k,expected)
 local old,historical=S.legacyGateOrdinalProbe(day,records)
 local right,ctx=S.gateOrdinalPatchProbe(day,records)
 assert(cmp(right,expected)==0 and cmp(B.add(old,1),right)==0,
  "Stage41 must repair historical zero-based ordinal")
 assert(ctx.mode=="STAGE_41_PATCH_20"
  and ctx.status=="PATCH_GATE_ORDINAL_COMPLETE"
  and ctx.commitToken==4 and #ctx.branchTrace==4
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.branchTrace[4]=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.currentHandler=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==4
  and ctx.diagnostics[4].code=="PATCH20_ZERO_BASED_TO_ONE_BASED"
  and ctx.metrics["discovery19.legacy.lookups"]==1
  and ctx.metrics["patch19.boundary.lookups"]==1
  and ctx.metrics["discovery20.legacy.ordinal.lookups"]==1
  and ctx.metrics["patch20.onebased.ordinal.lookups"]==1
  and ctx.stage39GateIndexSemanticState.correctedIndex==k
  and ctx.stage40GateOrdinalSemanticState.correctedGateIndex==k
  and ctx.stage40GateOrdinalSemanticState.zeroBasedInsteadOfOneBased==true
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.oneBasedInsteadOfZeroBased==true
  and ctx.semanticState.preservedLegacyCommitCount==3
  and ctx.semanticState.noYearLogic==true
  and ctx.semanticState.noPostStir12==true
  and cmp(ctx.semanticState.correctedOrdinalDecimal,right)==0,
  "Stage41 four-commit ownership invariant failed")
 assert(historical.commitToken==3 and #historical.branchTrace==3,
  "Stage41 changed historical independent probe")
 ctx.stage40GateOrdinalSemanticState.historicalOrdinalDecimal="tampered"
 assert(cmp(ctx.semanticState.correctedOrdinalDecimal,expected)==0,
  "Stage41 aliases historical Stage40 state")
 return ctx
end
for k=-7,7 do
 local day=B.from(O.ensureGateIndex(k))
 verify(day,gates,k,B.add(B.sub(day,O.ensureGateIndex(k)),1))
 exact=exact+1
 if k<=6 then
  local inside=B.add(day,1)
  verify(inside,gates,k,B.add(B.sub(inside,O.ensureGateIndex(k)),1))
  interior=interior+1
 end
end
assert(exact==15 and interior==14)
print("PASS Stage41 canonical: 15 exact + 14 interior one-based repairs, 4 commits")

local synthetic=0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=center}
 for n=1,8 do
  days[9-n]=B.sub(days[10-n],42+((n*41+scenario*37)%922))
  days[9+n]=B.add(days[8+n],42+((n*79+scenario*23)%922))
 end
 local rs={}
 for k=-8,8 do rs[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local target=B.add(days[k+9],5)
 local ctx=verify(target,rs,k,B.add(B.sub(target,days[k+9]),1))
 assert(cmp(ctx.semanticState.correctedOrdinalDecimal,6)==0
  and cmp(ctx.semanticState.historicalOrdinalDecimal,5)==0
  and ctx.stage40GateOrdinalSemanticState.historicalOrdinalDecimal=="tampered",
  "Stage41 synthetic BigInt mismatch or aliased state")
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage41 synthetic: 96 signed 2^127 BigInt ordinal corrections")

local rejected=0
local function reject(day,rs)
 assert(not pcall(S.gateOrdinalPatchProbe,day,rs),
  "Stage41 must reject malformed or out-of-window inputs")
 rejected=rejected+1
end
reject("wrong",gates)
reject(B.sub(gates[2].day,1),gates)
reject(B.add(gates[16].day,1),gates)
local r=copy(gates);table.remove(r,1);reject(O.FOUNDATION_DAY,r)
r=copy(gates);r[9].day=r[8].day;reject(O.FOUNDATION_DAY,r)
r=copy(gates);r[9].index=20;reject(O.FOUNDATION_DAY,r)
r=copy(gates);r[10].day=tostring(B.add(r[9].day,1000000));reject(O.FOUNDATION_DAY,r)
r=copy(gates);r.extra="bad";reject(O.FOUNDATION_DAY,r)
r=copy(gates);r[5].day="invalid";reject(O.FOUNDATION_DAY,r)
assert(rejected==9)
local a,ctxA=S.gateOrdinalPatchProbe(O.FOUNDATION_DAY,gates)
local b,ctxB=S.gateOrdinalPatchProbe(O.FOUNDATION_DAY,gates)
assert(cmp(a,b)==0 and ctxA~=ctxB
 and ctxA.semanticState~=ctxB.semanticState
 and ctxA.stage40GateOrdinalSemanticState~=ctxB.stage40GateOrdinalSemanticState
 and ctxA.stage39GateIndexSemanticState~=ctxB.stage39GateIndexSemanticState)
ctxA.semanticState.correctedOrdinalDecimal="tampered"
assert(ctxB.semanticState.correctedOrdinalDecimal~="tampered")
local f=assert(io.open(root.."/src/gate_ordinal_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage41 hardening: 9 rejects, 2 isolated replays, no oracle in production")
