-- Stage51/PATCH25: independent raw-endpoint midpoint equality oracle.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- test only: canonical gate input
local S=require("spaghetti")
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET","GATE_SIGNED_OFFSET_DIRECTION_PATCH",
 "LEGACY_GATE_PHASE_ONE_BASED","GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH",
 "LEGACY_MIDPOINT_TIE_BEFORE","GATE_MIDPOINT_EQUALITY_PATCH"
}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(day,records,k,a,b)
 -- Independent of the legacy/comparison implementation: derive from caller endpoints.
 local offset=B.sub(day,a)
 local gap=B.sub(b,a)
 local twice=B.add(offset,offset)
 local cmp=B.compare(twice,gap)
 local wanted=(cmp<0 and "BEFORE_MIDPOINT") or
  (cmp==0 and "AT_MIDPOINT") or "AFTER_MIDPOINT"
 local witness=(cmp<=0 and "BEFORE_MIDPOINT") or "AFTER_MIDPOINT"
 local historical,hctx=S.legacyGateMidpointProbe(day,records)
 local actual,ctx=S.gateMidpointPatchProbe(day,records)
 assert(historical==witness and actual==wanted,
  "PATCH25 endpoint oracle or legacy output mismatch")
 assert(hctx.mode=="STAGE_50_DISCOVERY_25" and hctx.commitToken==13
  and hctx.semanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and hctx.semanticState.legacyMidpointLabel==witness,
  "PATCH25 mutated historical Stage50 route")
 assert(ctx.mode=="STAGE_51_PATCH_25"
  and ctx.phase=="PATCH_MIDPOINT_TIE_EQUALITY"
  and ctx.status=="PATCH_MIDPOINT_COMPLETE"
  and ctx.commitToken==14 and #ctx.branchTrace==14
  and #ctx.diagnostics==14
  and ctx.currentHandler=="GATE_MIDPOINT_EQUALITY_PATCH"
  and ctx.diagnostics[13].code=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.diagnostics[14].code=="PATCH25_MIDPOINT_TIE_EQUALITY"
  and ctx.metrics["discovery25.midpoint.lookups"]==1
  and ctx.metrics["patch25.midpoint.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE"
  and ctx.stage49PatchedPhaseSemanticState.correctedFraction==
   tostring(offset).."/"..tostring(gap)
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage50LegacyMidpointSemanticState.legacyMidpointLabel==historical
  and ctx.stage50LegacyMidpointSemanticState.tieMislabeledBefore==true
  and ctx.semanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.exactPhaseFraction==tostring(offset).."/"..tostring(gap)
  and ctx.semanticState.offsetDecimal==tostring(offset)
  and ctx.semanticState.gapDecimal==tostring(gap)
  and ctx.semanticState.twiceOffsetDecimal==tostring(twice)
  and ctx.semanticState.legacyMidpointLabel==historical
  and ctx.semanticState.correctedMidpointLabel==actual
  and ctx.semanticState.tieEqualityRestored==true
  and ctx.semanticState.preservedHistoricalCommitCount==13
  and ctx.semanticState.ownedGateSnapshots==true
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.noNormativeOracleCalled,
  "PATCH25 semantic state, metrics or snapshots mismatch")
 for i=1,14 do assert(ctx.branchTrace[i]==trace[i],"PATCH25 trace order changed") end
 ctx.stage50LegacyMidpointSemanticState.legacyMidpointLabel="tampered"
 ctx.stage49PatchedPhaseSemanticState.correctedFraction="tampered"
 assert(ctx.semanticState.correctedMidpointLabel==actual
  and ctx.semanticState.exactPhaseFraction==tostring(offset).."/"..tostring(gap),
  "PATCH25 historical snapshots aliased into new state")
 return historical,actual,wanted
end

O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,closings=0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local historic,actual,wanted=verify(a,rs,k,a,b)
 assert(historic==actual and actual==wanted and actual=="BEFORE_MIDPOINT")
 openings=openings+1
 if k<=6 then
  historic,actual,wanted=verify(B.sub(b,1),rs,k,a,b)
  assert(historic==actual and actual==wanted and actual=="AFTER_MIDPOINT")
  closings=closings+1
 end
end
assert(openings==15 and closings==14)
print("PASS Stage51 canonical: 15 openings MATCH, 14 closings MATCH, 14 commits")

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
 local historic,actual,wanted=verify(B.add(a,half),indexed,k,a,b)
 assert(historic=="BEFORE_MIDPOINT" and actual=="AT_MIDPOINT"
  and actual==wanted and actual~=historic,
  "PATCH25 failed to repair authenticated Stage50 midpoint EXPECTED_RED")
 ties=ties+1
 historic,actual,wanted=verify(B.add(a,half-1),indexed,k,a,b)
 assert(historic=="BEFORE_MIDPOINT" and actual==historic and actual==wanted)
 historic,actual,wanted=verify(B.add(a,half+1),indexed,k,a,b)
 assert(historic=="AFTER_MIDPOINT" and actual==historic and actual==wanted)
 flanks=flanks+2
end
assert(ties==96 and flanks==192)
print("PASS Stage51 synthetic: 96 signed BigInt midpoint PATCHED, 192 flanks MATCH")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.gateMidpointPatchProbe,day,records),
  "PATCH25 accepted malformed/out-of-window input")
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
local x,a=S.gateMidpointPatchProbe(O.FOUNDATION_DAY,rs)
local y,b=S.gateMidpointPatchProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage50LegacyMidpointSemanticState~=b.stage50LegacyMidpointSemanticState
 and a.stage49PatchedPhaseSemanticState~=b.stage49PatchedPhaseSemanticState)
a.semanticState.correctedMidpointLabel="tampered"
a.stage50LegacyMidpointSemanticState.legacyMidpointLabel="tampered"
a.stage49PatchedPhaseSemanticState.correctedFraction="tampered"
assert(b.semanticState.correctedMidpointLabel~="tampered"
 and b.stage50LegacyMidpointSemanticState.legacyMidpointLabel~="tampered"
 and b.stage49PatchedPhaseSemanticState.correctedFraction~="tampered")
local f=assert(io.open(root.."/src/gate_midpoint_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage51 hardening: 9 rejects, 2 isolated replays, Stage50 EXPECTED_RED preserved")
