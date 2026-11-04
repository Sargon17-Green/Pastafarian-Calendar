-- Stage53/PATCH26: independent small-gap integer arithmetic oracle and historical gate.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- test-only gate fixture
local S=require("spaghetti")
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET","GATE_SIGNED_OFFSET_DIRECTION_PATCH",
 "LEGACY_GATE_PHASE_ONE_BASED","GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH",
 "LEGACY_MIDPOINT_TIE_BEFORE","GATE_MIDPOINT_EQUALITY_PATCH",
 "LEGACY_QUARTILE_STICKY_EDGE","GATE_QUARTILE_EDGE_PATCH"
}
local labels={"Q1","Q2","Q3","Q4"}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(day,records,k,a,b)
 -- Independent oracle: the validated gate gap is at most 963, so bounded
 -- integer // and % are exact even if the absolute signed day is ~2^127.
 local off=assert(B.toNumber(B.sub(day,a)))
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(off>=0 and off<gap and gap>=42 and gap<=963)
 local q=(4*off)//gap+1
 local boundary=(off>0 and (4*off)%gap==0)
 local expected=labels[q]
 local old=labels[q-(boundary and 1 or 0)]
 local historic,hctx=S.legacyGateQuartileProbe(day,records)
 local actual,ctx=S.gateQuartilePatchProbe(day,records)
 assert(historic==old and actual==expected,"PATCH26 independent oracle mismatch")
 assert(hctx.mode=="STAGE_53_PATCH_26" and hctx.commitToken==15 and hctx.semanticState.legacyQuartileLabel==historic)
 assert(ctx.mode=="STAGE_52_DISCOVERY_26"
  and ctx.phase=="PATCH_QUARTILE_EDGE_EQUALITY"
  and ctx.status=="PATCH_QUARTILE_COMPLETE"
  and ctx.commitToken==16 and #ctx.branchTrace==16 and #ctx.diagnostics==16
  and ctx.currentHandler=="GATE_QUARTILE_EDGE_PATCH"
  and ctx.diagnostics[15].code=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.diagnostics[16].code=="PATCH26_QUARTILE_EDGE_EQUALITY"
  and ctx.metrics["discovery26.quartile.lookups"]==1 and ctx.metrics["patch26.quartile.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.stage51PatchedMidpointSemanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "DISCOVERY26 historical context or metrics invalid")
 local st=ctx.semanticState
 assert(ctx.stage52LegacyQuartileSemanticState.source=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.stage52LegacyQuartileSemanticState.legacyQuartileLabel==historic)
 assert(st.source=="PATCH_26_QUARTILE_EDGE_EQUALITY")
 assert(st.correctedGateIndex==k
  and st.requestedDayDecimal==tostring(B.from(day))
  and st.offsetDecimal==tostring(B.sub(day,a))
  and st.gapDecimal==tostring(B.sub(b,a))
  and st.fourOffsetDecimal==tostring(B.add(B.add(B.sub(day,a),B.sub(day,a)),
                                      B.add(B.sub(day,a),B.sub(day,a))))
  and st.exactPhaseFraction==tostring(B.sub(day,a)).."/"..tostring(B.sub(b,a))
  and st.legacyQuartileLabel==old and st.correctedQuartileLabel==actual
  and st.edgeEqualityRestored
  and st.preservedHistoricalCommitCount==15 and st.ownedGateSnapshots
  and st.noYearLogic and st.noPostStir12 and st.noNormativeOracleCalled,
  "DISCOVERY26 state fields invalid")
 for i=1,16 do assert(ctx.branchTrace[i]==trace[i],"PATCH26 trace order") end
 local midpoint=((2*off<gap) and "BEFORE_MIDPOINT") or
                ((2*off==gap) and "AT_MIDPOINT") or "AFTER_MIDPOINT"
 assert(st.correctedMidpointLabel==midpoint
  and ctx.stage51PatchedMidpointSemanticState.correctedMidpointLabel==midpoint,
  "DISCOVERY26 corrupted Stage51 midpoint classification")
 ctx.stage51PatchedMidpointSemanticState.correctedMidpointLabel="tampered"
 ctx.stage50LegacyMidpointSemanticState.legacyMidpointLabel="tampered"
 ctx.stage49PatchedPhaseSemanticState.correctedFraction="tampered"
 assert(st.correctedMidpointLabel==midpoint
  and st.exactPhaseFraction==tostring(off).."/"..tostring(gap),
  "DISCOVERY26 aliases historical snapshots")
 return historic,actual,expected,boundary
end

O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,closings=0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local old,actual,right=verify(a,rs,k,a,b)
 assert(old=="Q1" and actual=="Q1" and right=="Q1")
 openings=openings+1
 if k<=6 then
  old,actual,right=verify(B.sub(b,1),rs,k,a,b)
  assert(old=="Q4" and actual=="Q4" and right=="Q4")
  closings=closings+1
 end
end
assert(openings==15 and closings==14)
print("PASS Stage53 canonical: 15 openings MATCH, 14 closings MATCH, 16 commits")

local red,flanks=0,0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=center}
 for n=1,8 do
  days[9-n]=B.sub(days[10-n],44+4*((n*41+scenario*37)%220))
  days[9+n]=B.add(days[8+n],44+4*((n*79+scenario*23)%220))
 end
 local indexed={}
 for k=-8,8 do indexed[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local a,b=days[k+9],days[k+10]
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(gap>=44 and gap<=920 and gap%4==0)
 local quarter=gap//4
 for boundary=1,3 do
  local anchor=B.add(a,quarter*boundary)
  local old,actual,right,edge=verify(anchor,indexed,k,a,b)
  assert(old==labels[boundary] and actual==labels[boundary+1] and right==actual and edge,
   "DISCOVERY26 failed expected-red at exact quarter edge")
  red=red+1
  old,actual,right=verify(B.sub(anchor,1),indexed,k,a,b)
  assert(old==actual and actual==right and old==labels[boundary])
  old,actual,right=verify(B.add(anchor,1),indexed,k,a,b)
  assert(old==actual and actual==right and old==labels[boundary+1])
  flanks=flanks+2
 end
end
assert(red==288 and flanks==576)
print("PASS Stage53 synthetic: 288 signed BigInt quartile PATCHED, 576 flanks MATCH")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.gateQuartilePatchProbe,day,records),
  "DISCOVERY26 accepted invalid or out-of-window input")
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
local x,a=S.gateQuartilePatchProbe(O.FOUNDATION_DAY,rs)
local y,b=S.gateQuartilePatchProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage52LegacyQuartileSemanticState~=b.stage52LegacyQuartileSemanticState
 and a.stage51PatchedMidpointSemanticState~=b.stage51PatchedMidpointSemanticState
 and a.stage50LegacyMidpointSemanticState~=b.stage50LegacyMidpointSemanticState
 and a.stage49PatchedPhaseSemanticState~=b.stage49PatchedPhaseSemanticState)
a.semanticState.correctedQuartileLabel="tampered"
a.stage52LegacyQuartileSemanticState.legacyQuartileLabel="tampered"
a.stage51PatchedMidpointSemanticState.correctedMidpointLabel="tampered"
assert(b.semanticState.correctedQuartileLabel~="tampered"
 and b.stage52LegacyQuartileSemanticState.legacyQuartileLabel~="tampered"
 and b.stage51PatchedMidpointSemanticState.correctedMidpointLabel~="tampered")
local f=assert(io.open(root.."/src/gate_quartile_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage53 hardening: 9 rejects, 2 isolated replays, Stage52 EXPECTED_RED preserved")
