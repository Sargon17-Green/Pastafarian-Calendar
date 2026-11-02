-- Stage49/PATCH24: independent endpoint oracle; Stage48 historical audit.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- tests only: canonical gate records
local S=require("spaghetti")
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET","GATE_SIGNED_OFFSET_DIRECTION_PATCH",
 "LEGACY_GATE_PHASE_ONE_BASED","GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH"
}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(day,records,k,a,b)
 -- Raw caller-supplied endpoints, without importing any production phase formula.
 local n=B.sub(day,a)
 local g=B.sub(b,a)
 local expected=tostring(n).."/"..tostring(g)
 local witness=tostring(B.add(n,1)).."/"..tostring(g)
 local historical,hctx=S.legacyGatePhaseProbe(day,records)
 local actual,ctx=S.gatePhasePatchProbe(day,records)
 assert(historical==witness and historical~=expected and actual==expected
  and actual~=historical,"PATCH24 endpoint comparison failed")
 assert(hctx.mode=="STAGE_48_DISCOVERY_24" and hctx.status=="LEGACY_PHASE_COMPLETE"
  and hctx.commitToken==11 and hctx.currentHandler=="LEGACY_GATE_PHASE_ONE_BASED"
  and hctx.semanticState.oneBasedNumerator==true
  and hctx.semanticState.fraction==historical,
  "PATCH24 changed authenticated Stage48 historical probe")
 assert(ctx.mode=="STAGE_49_PATCH_24" and ctx.phase=="PATCH_EXACT_GATE_PHASE"
  and ctx.status=="PATCH_PHASE_COMPLETE"
  and ctx.commitToken==12 and #ctx.branchTrace==12 and #ctx.diagnostics==12
  and ctx.currentHandler=="GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH"
  and ctx.diagnostics[11].code=="DISCOVERY24_PHASE_OFF_BY_ONE"
  and ctx.diagnostics[12].code=="PATCH24_PHASE_NUMERATOR_ZERO_BASED"
  and ctx.metrics["discovery24.phase.lookups"]==1
  and ctx.metrics["patch24.phase.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.legacyOneBasedPhaseFraction==historical
  and ctx.stage48LegacyPhaseSemanticState.source=="DISCOVERY24_ONE_BASED_PHASE"
  and ctx.stage48LegacyPhaseSemanticState.fraction==historical
  and ctx.stage48LegacyPhaseSemanticState.oneBasedNumerator==true
  and ctx.stage48LegacyPhaseSemanticState.correctedGateIndex==k
  and ctx.stage47SignedOffsetSemanticState.closingDirectionRestored==true
  and ctx.semanticState.source=="PATCH_24_ZERO_BASED_PHASE"
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.historicalFraction==historical
  and ctx.semanticState.correctedFraction==actual
  and ctx.semanticState.historicalNumeratorDecimal==tostring(B.add(n,1))
  and ctx.semanticState.correctedNumeratorDecimal==tostring(n)
  and ctx.semanticState.denominatorDecimal==tostring(g)
  and ctx.semanticState.zeroBasedNumerator==true
  and ctx.semanticState.exactDenominator==true
  and ctx.semanticState.unreducedFraction==true
  and ctx.semanticState.preservedHistoricalCommitCount==11
  and ctx.semanticState.ownedGateSnapshots==true
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.noNormativeOracleCalled,
  "PATCH24 trace, snapshot or semantic state mismatch")
 for i=1,12 do assert(ctx.branchTrace[i]==trace[i],"PATCH24 commit order changed") end
 ctx.stage48LegacyPhaseSemanticState.fraction="altered"
 ctx.stage47SignedOffsetSemanticState.correctedGateIndex=999
 assert(ctx.semanticState.correctedFraction==actual and
  ctx.semanticState.correctedGateIndex==k)
 return actual,historical
end

O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,middles,closings=0,0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local gap=assert(B.toNumber(B.sub(b,a)))
 local corrected,historical=verify(a,rs,k,a,b)
 assert(corrected=="0/"..gap and historical=="1/"..gap)
 openings=openings+1
 if k<=6 then
  local n=math.floor(gap/2)
  corrected,historical=verify(B.add(a,n),rs,k,a,b)
  assert(corrected==tostring(n).."/"..gap and
   historical==tostring(n+1).."/"..gap)
  middles=middles+1
  corrected,historical=verify(B.sub(b,1),rs,k,a,b)
  assert(corrected==tostring(gap-1).."/"..gap and historical==tostring(gap).."/"..gap)
  closings=closings+1
 end
end
assert(openings==15 and middles==14 and closings==14)
print("PASS Stage49 canonical: 15 openings, 14 midpoints, 14 closings exact-phase PATCHED, 12 commits")

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
 local corrected,historical=verify(B.sub(b,offset),indexed,k,a,b)
 assert(corrected==tostring(gap-offset).."/"..gap and
  historical==tostring(gap-offset+1).."/"..gap)
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage49 synthetic: 96 signed BigInt exact-fraction PATCHED")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.gatePhasePatchProbe,day,records),
  "PATCH24 accepted malformed/out-of-window input")
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
local x,a=S.gatePhasePatchProbe(O.FOUNDATION_DAY,rs)
local y,b=S.gatePhasePatchProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage48LegacyPhaseSemanticState~=b.stage48LegacyPhaseSemanticState)
a.semanticState.correctedFraction="altered"
a.stage48LegacyPhaseSemanticState.fraction="altered"
assert(b.semanticState.correctedFraction~="altered"
 and b.stage48LegacyPhaseSemanticState.fraction~="altered")
local f=assert(io.open(root.."/src/gate_phase_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage49 hardening: 9 rejects, 2 isolated replays, Stage48 historical EXPECTED_RED preserved")
