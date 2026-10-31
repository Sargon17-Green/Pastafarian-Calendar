-- Stage43 PATCH21: include the current day; Stage42 historic five commits intact.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- independent gate construction, test only
local S=require("spaghetti")
local cmp=B.compare
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return out
end
local function verify(day,records,k,closing)
 local old,historicCtx=S.legacyGateReverseOrdinalProbe(day,records)
 local corrected,ctx=S.gateReverseOrdinalPatchProbe(day,records)
 local oracle=B.sub(closing,day) -- direct independent closing-boundary oracle
 assert(cmp(corrected,oracle)==0
  and cmp(B.add(old,1),corrected)==0,
  "PATCH21: inclusive reverse ordinal differs from independent oracle")
 assert(historicCtx.commitToken==5 and #historicCtx.branchTrace==5
  and historicCtx.status=="LEGACY_GATE_REVERSE_ORDINAL_COMPLETE"
  and historicCtx.semanticState.excludesCurrentDay==true,
  "PATCH21: historical Stage42 probe changed")
 assert(ctx.mode=="STAGE_43_PATCH_21"
  and ctx.status=="PATCH_GATE_REVERSE_ORDINAL_COMPLETE"
  and ctx.commitToken==6 and #ctx.branchTrace==6
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.branchTrace[4]=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.branchTrace[5]=="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
  and ctx.branchTrace[6]=="GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH"
  and ctx.currentHandler=="GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH"
  and #ctx.diagnostics==6
  and ctx.diagnostics[6].code=="PATCH21_REVERSE_ORDINAL_INCLUDES_CURRENT_DAY"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["discovery19.legacy.lookups"]==1
  and ctx.metrics["patch19.boundary.lookups"]==1
  and ctx.metrics["discovery20.legacy.ordinal.lookups"]==1
  and ctx.metrics["patch20.onebased.ordinal.lookups"]==1
  and ctx.metrics["discovery21.legacy.reverse.lookups"]==1
  and ctx.metrics["patch21.inclusive.reverse.lookups"]==1
  and ctx.stage41GateOrdinalSemanticState.correctedGateIndex==k
  and ctx.stage42GateReverseOrdinalSemanticState.excludesCurrentDay==true
  and ctx.stage42GateReverseOrdinalSemanticState.preservedHistoricalCommitCount==4
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.includesCurrentDay==true
  and ctx.semanticState.preservedLegacyCommitCount==5
  and ctx.semanticState.noNormativeOracleCalled==true
  and ctx.semanticState.noYearLogic==true and ctx.semanticState.noPostStir12==true
  and cmp(ctx.semanticState.correctedReverseOrdinalDecimal,corrected)==0
  and cmp(ctx.semanticState.historicalReverseOrdinalDecimal,old)==0,
  "PATCH21: six-commit, ownership or diagnostic invariant failed")
 ctx.stage42GateReverseOrdinalSemanticState.historicalReverseOrdinalDecimal="tampered"
 assert(cmp(ctx.semanticState.correctedReverseOrdinalDecimal,oracle)==0
  and cmp(ctx.legacyGateReverseOrdinalDecimal,old)==0,
  "PATCH21: Stage42 state aliases Stage43")
 return corrected,ctx
end
O.resetGateCache()
local gates={}
for k=-8,8 do
 gates[k+9]={index=k,day=tostring(O.ensureGateIndex(k))}
end
local openings,closings=0,0
for k=-7,7 do
 local opening=B.from(gates[k+9].day)
 local closing=B.from(gates[k+10].day)
 local gap=B.sub(closing,opening)
 local first=verify(opening,gates,k,closing)
 assert(cmp(first,gap)==0)
 openings=openings+1
 -- Locked Stage38 target validator excludes the last day of k=7.
 if k<=6 then
  local last=B.sub(closing,1)
  local final=verify(last,gates,k,closing)
  assert(cmp(final,1)==0)
  closings=closings+1
 end
end
assert(openings==15 and closings==14)
print("PASS Stage43 canonical: 15 opening + 14 closing reverse-ordinal repairs, 6 commits")

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
 local closing=days[k+10]
 local target=B.sub(closing,1)
 local corrected,ctx=verify(target,rs,k,closing)
 assert(cmp(corrected,1)==0
  and cmp(ctx.semanticState.historicalReverseOrdinalDecimal,0)==0)
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage43 synthetic: 96 signed BigInt inclusive reverse-ordinal repairs")

local rejected=0
local function reject(day,rs)
 assert(not pcall(S.gateReverseOrdinalPatchProbe,day,rs),
  "PATCH21: malformed or out-of-window input accepted")
 rejected=rejected+1
end
reject("invalid",gates)
reject(B.sub(gates[2].day,1),gates)
reject(B.sub(gates[17].day,1),gates) -- G(8)-1 is outside historical allowed max G(7)
local t=copy(gates);table.remove(t,1);reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[9].day=t[8].day;reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[9].index=20;reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[10].day=tostring(B.add(t[9].day,1000000));reject(O.FOUNDATION_DAY,t)
t=copy(gates);t.extra="bad";reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[5].day="invalid";reject(O.FOUNDATION_DAY,t)
assert(rejected==9)
local a,first=S.gateReverseOrdinalPatchProbe(O.FOUNDATION_DAY,gates)
local b,second=S.gateReverseOrdinalPatchProbe(O.FOUNDATION_DAY,gates)
assert(cmp(a,b)==0 and first~=second
 and first.semanticState~=second.semanticState
 and first.stage42GateReverseOrdinalSemanticState~=second.stage42GateReverseOrdinalSemanticState
 and first.stage41GateOrdinalSemanticState~=second.stage41GateOrdinalSemanticState)
first.stage42GateReverseOrdinalSemanticState.historicalReverseOrdinalDecimal="tampered"
first.semanticState.correctedReverseOrdinalDecimal="tampered"
assert(second.semanticState.correctedReverseOrdinalDecimal~="tampered"
 and second.stage42GateReverseOrdinalSemanticState.historicalReverseOrdinalDecimal~="tampered")
local f=assert(io.open(root.."/src/gate_reverse_ordinal_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage43 hardening: 9 rejects, 2 isolated replays, no oracle in production")
