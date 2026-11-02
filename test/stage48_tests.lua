-- Stage48 DISCOVERY24: test-only independent endpoint oracle.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET","GATE_SIGNED_OFFSET_DIRECTION_PATCH",
 "LEGACY_GATE_PHASE_ONE_BASED"
}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(target,records,k,a,b)
 local actual,ctx=S.legacyGatePhaseProbe(target,records)
 local n=B.sub(target,a)
 local g=B.sub(b,a)
 local expected=tostring(n).."/"..tostring(g)
 local historical=tostring(B.add(n,1)).."/"..tostring(g)
 assert(actual==historical and actual~=expected,"DISCOVERY24 expected-RED mismatch")
 assert(ctx.mode=="STAGE_48_DISCOVERY_24" and ctx.status=="LEGACY_PHASE_COMPLETE"
  and ctx.commitToken==11 and #ctx.branchTrace==11 and #ctx.diagnostics==11
  and ctx.currentHandler=="LEGACY_GATE_PHASE_ONE_BASED"
  and ctx.diagnostics[11].code=="DISCOVERY24_PHASE_OFF_BY_ONE"
  and ctx.metrics["discovery24.phase.lookups"]==1
  and ctx.metrics["patch23.signed.offsets"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.stage47SignedOffsetSemanticState.source=="PATCH_23_NEAREST_GATE_SIGNED_OFFSET"
  and ctx.stage47SignedOffsetSemanticState.closingDirectionRestored==true
  and ctx.stage47SignedOffsetSemanticState.correctedGateIndex==k
  and ctx.semanticState.source=="DISCOVERY24_ONE_BASED_PHASE"
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.historicalNumeratorDecimal==tostring(B.add(n,1))
  and ctx.semanticState.gapDecimal==tostring(g)
  and ctx.semanticState.fraction==actual
  and ctx.semanticState.oneBasedNumerator and ctx.semanticState.exactDenominator
  and ctx.semanticState.preservedHistoricalCommitCount==10
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.noNormativeOracleCalled)
 for i=1,11 do assert(ctx.branchTrace[i]==trace[i]) end
 ctx.stage47SignedOffsetSemanticState.correctedGateIndex=111
 assert(ctx.semanticState.correctedGateIndex==k)
 return actual,expected
end
O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,middles,closings=0,0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local gap=assert(B.toNumber(B.sub(b,a)))
 local actual,correct=verify(a,rs,k,a,b)
 assert(actual=="1/"..gap and correct=="0/"..gap)
 openings=openings+1
 if k<=6 then
  local n=math.floor(gap/2)
  actual,correct=verify(B.add(a,n),rs,k,a,b)
  assert(actual==tostring(n+1).."/"..gap and correct==tostring(n).."/"..gap)
  middles=middles+1
  actual,correct=verify(B.sub(b,1),rs,k,a,b)
  assert(actual==tostring(gap).."/"..gap and correct==tostring(gap-1).."/"..gap)
  closings=closings+1
 end
end
assert(openings==15 and middles==14 and closings==14)
print("PASS Stage48 canonical: 15 openings, 14 midpoints, 14 closings exact-phase EXPECTED_RED, 11 commits")
local synthetic=0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=center}
 for n=1,8 do
  days[9-n]=B.sub(days[10-n],42+2*((n*41+scenario*37)%461))
  days[9+n]=B.add(days[8+n],42+2*((n*79+scenario*23)%461))
 end
 local indexed={}
 for k=-8,8 do indexed[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local a,b=days[k+9],days[k+10]
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(gap>=42 and gap<=962 and gap%2==0)
 local offset=2+(scenario%5)
 local actual,correct=verify(B.sub(b,offset),indexed,k,a,b)
 assert(actual==tostring(gap-offset+1).."/"..gap
  and correct==tostring(gap-offset).."/"..gap)
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage48 synthetic: 96 signed BigInt exact-fraction EXPECTED_RED")
local rejects=0
local function reject(day,records)
 assert(not pcall(S.legacyGatePhaseProbe,day,records))
 rejects=rejects+1
end
reject("invalid",rs)
reject(B.sub(rs[2].day,1),rs)
reject(B.sub(rs[17].day,1),rs)
local t=copy(rs);table.remove(t,1);reject(O.FOUNDATION_DAY,t)
t=copy(rs);t[9].day=t[8].day;reject(O.FOUNDATION_DAY,t)
t=copy(rs);t[9].index=20;reject(O.FOUNDATION_DAY,t)
t=copy(rs);t[10].day=tostring(B.add(t[9].day,1000000));reject(O.FOUNDATION_DAY,t)
t=copy(rs);t.extra="bad";reject(O.FOUNDATION_DAY,t)
t=copy(rs);t[5].day="invalid";reject(O.FOUNDATION_DAY,t)
assert(rejects==9)
local x,a=S.legacyGatePhaseProbe(O.FOUNDATION_DAY,rs)
local y,b=S.legacyGatePhaseProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage47SignedOffsetSemanticState~=b.stage47SignedOffsetSemanticState)
a.semanticState.fraction="changed"
a.stage47SignedOffsetSemanticState.correctedGateIndex=999
assert(b.semanticState.fraction~="changed"
 and b.stage47SignedOffsetSemanticState.correctedGateIndex~=999)
local f=assert(io.open(root.."/src/legacy_gate_phase.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage48 hardening: 9 rejects, 2 isolated replays, no oracle in production")
