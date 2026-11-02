-- Stage50/DISCOVERY25: midpoint comparison oracle from raw endpoints, test-only.
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
 "LEGACY_GATE_PHASE_ONE_BASED","GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH",
 "LEGACY_MIDPOINT_TIE_BEFORE"
}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(day,records,k,a,b)
 -- Independently derive three-way midpoint classification from exact raw endpoints.
 local offset=B.sub(day,a)
 local gap=B.sub(b,a)
 local doubled=B.add(offset,offset)
 local cmp=B.compare(doubled,gap)
 local expected=(cmp<0 and "BEFORE_MIDPOINT") or
  (cmp==0 and "AT_MIDPOINT") or "AFTER_MIDPOINT"
 local witness=(cmp==0 and "BEFORE_MIDPOINT") or expected
 local actual,ctx=S.legacyGateMidpointProbe(day,records)
 assert(actual==witness,"DISCOVERY25 actual differed from controlled legacy contract")
 assert(ctx.mode=="STAGE_50_DISCOVERY_25"
  and ctx.phase=="LEGACY_MIDPOINT_TIE_BEFORE"
  and ctx.status=="LEGACY_MIDPOINT_COMPLETE"
  and ctx.commitToken==13 and #ctx.branchTrace==13 and #ctx.diagnostics==13
  and ctx.currentHandler=="LEGACY_MIDPOINT_TIE_BEFORE"
  and ctx.diagnostics[13].code=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.metrics["discovery25.midpoint.lookups"]==1
  and ctx.metrics["patch24.phase.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE"
  and ctx.stage49PatchedPhaseSemanticState.correctedGateIndex==k
  and ctx.stage49PatchedPhaseSemanticState.correctedFraction==
   tostring(offset).."/"..tostring(gap)
  and ctx.semanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.exactPhaseFraction==tostring(offset).."/"..tostring(gap)
  and ctx.semanticState.offsetDecimal==tostring(offset)
  and ctx.semanticState.gapDecimal==tostring(gap)
  and ctx.semanticState.twiceOffsetDecimal==tostring(doubled)
  and ctx.semanticState.legacyMidpointLabel==actual
  and ctx.semanticState.tieMislabeledBefore
  and ctx.semanticState.preservedHistoricalCommitCount==12
  and ctx.semanticState.ownedGateSnapshots and ctx.semanticState.noYearLogic
  and ctx.semanticState.noPostStir12 and ctx.semanticState.noNormativeOracleCalled,
  "DISCOVERY25 context, snapshots, provenance or trace changed")
 for i=1,13 do assert(ctx.branchTrace[i]==trace[i],"DISCOVERY25 trace order") end
 ctx.stage49PatchedPhaseSemanticState.correctedFraction="tampered"
 assert(ctx.semanticState.exactPhaseFraction==tostring(offset).."/"..tostring(gap),
  "DISCOVERY25 snapshots aliased")
 return actual,expected
end
O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local opens,closings=0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local got,want=verify(a,rs,k,a,b)
 assert(got=="BEFORE_MIDPOINT" and got==want)
 opens=opens+1
 if k<=6 then
  got,want=verify(B.sub(b,1),rs,k,a,b)
  assert(got=="AFTER_MIDPOINT" and got==want)
  closings=closings+1
 end
end
assert(opens==15 and closings==14)
print("PASS Stage50 canonical: 15 openings MATCH, 14 closings MATCH, 13 commits")

local ties,flanks=0,0
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
 local half=gap//2
 local got,want=verify(B.add(a,half),indexed,k,a,b)
 assert(got=="BEFORE_MIDPOINT" and want=="AT_MIDPOINT" and got~=want,
  "DISCOVERY25 midpoint expected-RED was not reproduced")
 ties=ties+1
 got,want=verify(B.add(a,half-1),indexed,k,a,b)
 assert(got=="BEFORE_MIDPOINT" and got==want)
 got,want=verify(B.add(a,half+1),indexed,k,a,b)
 assert(got=="AFTER_MIDPOINT" and got==want)
 flanks=flanks+2
end
assert(ties==96 and flanks==192)
print("PASS Stage50 synthetic: 96 signed BigInt midpoint EXPECTED_RED, 192 flanks MATCH")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.legacyGateMidpointProbe,day,records))
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
local x,a=S.legacyGateMidpointProbe(O.FOUNDATION_DAY,rs)
local y,b=S.legacyGateMidpointProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage49PatchedPhaseSemanticState~=b.stage49PatchedPhaseSemanticState)
a.semanticState.legacyMidpointLabel="tampered"
a.stage49PatchedPhaseSemanticState.correctedFraction="tampered"
assert(b.semanticState.legacyMidpointLabel~="tampered"
 and b.stage49PatchedPhaseSemanticState.correctedFraction~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_midpoint.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage50 hardening: 9 rejects, 2 isolated replays, prior Stage49 patch preserved")
