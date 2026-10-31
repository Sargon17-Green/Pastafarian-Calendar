-- Stage40 DISCOVERY20: one-based ordinal is a defined future contract.
-- The zero-based discrepancy is intentionally introduced, not a discovered bug.
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
for k=-7,7 do
 local day=B.from(O.ensureGateIndex(k))
 local historical,ctx=S.legacyGateOrdinalProbe(day,gates)
 local expected=B.add(B.sub(day,O.ensureGateIndex(k)),1)
 assert(cmp(historical,0)==0 and cmp(B.add(historical,1),expected)==0,
  "Stage40 gate equality requires ordinal one, not zero")
 assert(ctx.mode=="STAGE_40_DISCOVERY_20"
  and ctx.status=="LEGACY_GATE_ORDINAL_COMPLETE"
  and ctx.commitToken==3 and #ctx.branchTrace==3
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.currentHandler=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==3
  and ctx.diagnostics[3].code=="DISCOVERY20_ZERO_BASED_GATE_ORDINAL"
  and ctx.metrics["discovery19.legacy.lookups"]==1
  and ctx.metrics["patch19.boundary.lookups"]==1
  and ctx.metrics["discovery20.legacy.ordinal.lookups"]==1
  and ctx.stage39GateIndexSemanticState.correctedIndex==k
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.zeroBasedInsteadOfOneBased==true
  and ctx.semanticState.noCanonicalOrdinalComputed==true
  and ctx.semanticState.noYearLogic==true
  and ctx.semanticState.noPostStir12==true,
  "Stage40 requires real third semantic commit with frozen Stage39 trace")
 ctx.stage39GateIndexSemanticState.gateDayDecimals[1]="changed"
 assert(ctx.semanticState.openingGateDayDecimal==tostring(day),
  "Stage40 semantic state aliases prior state")
 exact=exact+1
 if k<=6 then
  local inside=B.add(day,1)
  local prior=S.gateIndexAtOrBeforeSpaghetti(inside,gates)
  local value,owned=S.legacyGateOrdinalProbe(inside,gates)
  local oracle=B.add(B.sub(inside,O.ensureGateIndex(k)),1)
  assert(prior==k and cmp(value,1)==0
   and cmp(B.add(value,1),oracle)==0
   and owned.semanticState.correctedGateIndex==k,
   "Stage40 interior ordinal discrepancy missing")
  interior=interior+1
 end
end
assert(exact==15 and interior==14)
print("PASS Stage40 canonical: 15 exact ordinal EXPECTED_RED, 14 interior EXPECTED_RED, 3 commits")

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
 local value,ctx=S.legacyGateOrdinalProbe(target,rs)
 local canonical=B.add(B.sub(target,days[k+9]),1)
 assert(ctx.semanticState.correctedGateIndex==k
  and cmp(value,5)==0 and cmp(canonical,6)==0
  and cmp(B.add(value,1),canonical)==0
  and cmp(ctx.semanticState.nextGateDayDecimal,days[k+10])==0,
  "Stage40 synthetic large signed ordinal mismatch")
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage40 synthetic: 96 signed 2^127 BigInt chains, 96 deliberate ordinal RED")

local rejected=0
local function reject(day,rs)
 assert(not pcall(S.legacyGateOrdinalProbe,day,rs),
  "Stage40 must reject malformed or out-of-window inputs")
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
local a,ctxA=S.legacyGateOrdinalProbe(O.FOUNDATION_DAY,gates)
local b,ctxB=S.legacyGateOrdinalProbe(O.FOUNDATION_DAY,gates)
assert(cmp(a,b)==0 and ctxA~=ctxB
 and ctxA.semanticState~=ctxB.semanticState
 and ctxA.stage39GateIndexSemanticState~=ctxB.stage39GateIndexSemanticState)
ctxA.semanticState.historicalOrdinalDecimal="tampered"
assert(ctxB.semanticState.historicalOrdinalDecimal~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_ordinal.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage40 hardening: 9 rejects, 2 isolated replays, no oracle in production")
