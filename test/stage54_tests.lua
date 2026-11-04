-- Stage54/DISCOVERY27: independent integer oracle for controlled octile-edge fault.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- test-only, never imported by production
local S=require("spaghetti")
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET","GATE_SIGNED_OFFSET_DIRECTION_PATCH",
 "LEGACY_GATE_PHASE_ONE_BASED","GATE_PHASE_NUMERATOR_ZERO_BASED_PATCH",
 "LEGACY_MIDPOINT_TIE_BEFORE","GATE_MIDPOINT_EQUALITY_PATCH",
 "LEGACY_QUARTILE_STICKY_EDGE","GATE_QUARTILE_EDGE_PATCH",
 "LEGACY_OCTILE_STICKY_EDGE"
}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(day,records,k,a,b)
 local off=assert(B.toNumber(B.sub(day,a)))
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(off>=0 and off<gap and gap>=42 and gap<=963)
 local rightBucket=(8*off)//gap+1
 local exact=(off>0 and (8*off)%gap==0)
 local expected="E"..rightBucket
 local historicalExpected="E"..(rightBucket-(exact and 1 or 0))
 local quartileExpected="Q"..((4*off)//gap+1)
 local actual,ctx=S.legacyGateOctileProbe(day,records)
 assert(actual==historicalExpected,
  "DISCOVERY27 controlled legacy result / independent oracle mismatch")
 assert(ctx.mode=="STAGE_54_DISCOVERY_27"
  and ctx.phase=="LEGACY_OCTILE_STICKY_EDGE"
  and ctx.status=="LEGACY_OCTILE_COMPLETE"
  and ctx.commitToken==17 and #ctx.branchTrace==17 and #ctx.diagnostics==17
  and ctx.currentHandler=="LEGACY_OCTILE_STICKY_EDGE"
  and ctx.diagnostics[17].code=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and ctx.metrics["discovery27.octile.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "DISCOVERY27 historical context invalid")
 local st=ctx.semanticState
 assert(st.source=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and st.correctedGateIndex==k
  and st.requestedDayDecimal==tostring(B.from(day))
  and st.offsetDecimal==tostring(B.sub(day,a))
  and st.gapDecimal==tostring(B.sub(b,a))
  and st.eightOffsetDecimal==tostring(B.add(B.add(B.add(B.sub(day,a),B.sub(day,a)),B.add(B.sub(day,a),B.sub(day,a))),
     B.add(B.add(B.sub(day,a),B.sub(day,a)),B.add(B.sub(day,a),B.sub(day,a)))))
  and st.exactPhaseFraction==tostring(off).."/"..tostring(gap)
  and st.correctedQuartileLabel==quartileExpected
  and st.legacyOctileLabel==actual
  and st.edgeStickyPrevious and st.preservedHistoricalCommitCount==16
  and st.ownedGateSnapshots and st.noYearLogic and st.noPostStir12
  and st.noNormativeOracleCalled,
  "DISCOVERY27 semantic state invalid")
 assert(ctx.stage53PatchedQuartileSemanticState.source=="PATCH_26_QUARTILE_EDGE_EQUALITY"
  and ctx.stage53PatchedQuartileSemanticState.correctedQuartileLabel==quartileExpected
  and ctx.stage52LegacyQuartileSemanticState.source=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.stage51PatchedMidpointSemanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "DISCOVERY27 mutated earlier layers")
 for i=1,17 do assert(ctx.branchTrace[i]==trace[i],"DISCOVERY27 trace order") end
 local qBefore=ctx.stage53PatchedQuartileSemanticState.correctedQuartileLabel
 ctx.stage53PatchedQuartileSemanticState.correctedQuartileLabel="tampered"
 ctx.stage52LegacyQuartileSemanticState.legacyQuartileLabel="tampered"
 ctx.stage51PatchedMidpointSemanticState.correctedMidpointLabel="tampered"
 assert(st.correctedQuartileLabel==qBefore
  and st.exactPhaseFraction==tostring(off).."/"..tostring(gap),
  "DISCOVERY27 aliases historical snapshots")
 return actual,expected,exact
end

O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,closings=0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local old,right=verify(a,rs,k,a,b)
 assert(old=="E1" and right=="E1")
 openings=openings+1
 if k<=6 then
  old,right=verify(B.sub(b,1),rs,k,a,b)
  assert(old=="E8" and right=="E8")
  closings=closings+1
 end
end
assert(openings==15 and closings==14)
print("PASS Stage54 canonical: 15 openings MATCH, 14 closings MATCH, 17 commits")

local red,flanks=0,0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=center}
 for n=1,8 do
  days[9-n]=B.sub(days[10-n],48+8*((n*41+scenario*37)%114))
  days[9+n]=B.add(days[8+n],48+8*((n*79+scenario*23)%114))
 end
 local indexed={}
 for k=-8,8 do indexed[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local a,b=days[k+9],days[k+10]
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(gap>=48 and gap<=952 and gap%8==0)
 local eighth=gap//8
 for boundary=1,7 do
  local anchor=B.add(a,eighth*boundary)
  local old,right,edge=verify(anchor,indexed,k,a,b)
  assert(old=="E"..boundary and right=="E"..(boundary+1) and edge,
   "DISCOVERY27 expected-red not reproduced on exact octile edge")
  red=red+1
  old,right=verify(B.sub(anchor,1),indexed,k,a,b)
  assert(old==right and old=="E"..boundary)
  old,right=verify(B.add(anchor,1),indexed,k,a,b)
  assert(old==right and old=="E"..(boundary+1))
  flanks=flanks+2
 end
end
assert(red==672 and flanks==1344)
print("PASS Stage54 synthetic: 672 signed BigInt octile EXPECTED_RED, 1344 flanks MATCH")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.legacyGateOctileProbe,day,records),
  "DISCOVERY27 unexpectedly accepted invalid input")
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
local x,a=S.legacyGateOctileProbe(O.FOUNDATION_DAY,rs)
local y,b=S.legacyGateOctileProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage53PatchedQuartileSemanticState~=b.stage53PatchedQuartileSemanticState
 and a.stage52LegacyQuartileSemanticState~=b.stage52LegacyQuartileSemanticState
 and a.stage51PatchedMidpointSemanticState~=b.stage51PatchedMidpointSemanticState
 and a.stage50LegacyMidpointSemanticState~=b.stage50LegacyMidpointSemanticState
 and a.stage49PatchedPhaseSemanticState~=b.stage49PatchedPhaseSemanticState)
a.semanticState.legacyOctileLabel="tampered"
a.stage53PatchedQuartileSemanticState.correctedQuartileLabel="tampered"
a.stage52LegacyQuartileSemanticState.legacyQuartileLabel="tampered"
assert(b.semanticState.legacyOctileLabel~="tampered"
 and b.stage53PatchedQuartileSemanticState.correctedQuartileLabel~="tampered"
 and b.stage52LegacyQuartileSemanticState.legacyQuartileLabel~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_octile.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage54 hardening: 9 rejects, 2 isolated replays, Stage53 PATCHED preserved")
