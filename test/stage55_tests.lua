-- Stage55/PATCH27: independent bounded-integer oracle; preserves Stage54 EXPECTED_RED.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- only test fixture, never required by production
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
 "LEGACY_OCTILE_STICKY_EDGE","GATE_OCTILE_EDGE_PATCH"
}
local function copy(rs)
 local t={}
 for i=1,#rs do t[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return t
end
local function verify(day,records,k,a,b)
 -- Mathematical reference uses small <=963 interval gaps after exact BigInt subtraction.
 -- This is intentionally independent of production's repeated-add/compare classifier.
 local off=assert(B.toNumber(B.sub(day,a)))
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(off>=0 and off<gap and gap>=42 and gap<=963)
 local bucket=(8*off)//gap+1
 local edge=(off>0 and (8*off)%gap==0)
 local right="E"..bucket
 local left="E"..(bucket-(edge and 1 or 0))
 local q="Q"..((4*off)//gap+1)
 local old,hctx=S.legacyGateOctileProbe(day,records)
 local actual,ctx=S.gateOctilePatchProbe(day,records)
 assert(old==left and actual==right,
  "PATCH27 independent oracle disagrees with historical or patched result")
 assert(hctx.mode=="STAGE_54_DISCOVERY_27" and hctx.commitToken==17
  and hctx.semanticState.source=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and hctx.semanticState.legacyOctileLabel==old,
  "PATCH27 Stage54 preserved probe failed")
 assert(ctx.mode=="STAGE_55_PATCH_27"
  and ctx.phase=="PATCH_OCTILE_EDGE_EQUALITY"
  and ctx.status=="PATCH_OCTILE_COMPLETE"
  and ctx.commitToken==18 and #ctx.branchTrace==18 and #ctx.diagnostics==18
  and ctx.currentHandler=="GATE_OCTILE_EDGE_PATCH"
  and ctx.diagnostics[17].code=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and ctx.diagnostics[18].code=="PATCH27_OCTILE_EDGE_EQUALITY"
  and ctx.metrics["discovery27.octile.lookups"]==1
  and ctx.metrics["patch27.octile.repairs"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil,
  "PATCH27 context / transaction / metrics invalid")
 local st=ctx.semanticState
 assert(st.source=="PATCH_27_OCTILE_EDGE_EQUALITY"
  and st.correctedGateIndex==k
  and st.requestedDayDecimal==tostring(B.from(day))
  and st.offsetDecimal==tostring(B.sub(day,a))
  and st.gapDecimal==tostring(B.sub(b,a))
  and st.eightOffsetDecimal==tostring(B.add(B.add(B.add(B.sub(day,a),B.sub(day,a)),
   B.add(B.sub(day,a),B.sub(day,a))),B.add(B.add(B.sub(day,a),B.sub(day,a)),
   B.add(B.sub(day,a),B.sub(day,a)))))
  and st.exactPhaseFraction==tostring(off).."/"..tostring(gap)
  and st.correctedQuartileLabel==q
  and st.legacyOctileLabel==old and st.correctedOctileLabel==actual
  and st.edgeEqualityRestored and st.preservedHistoricalCommitCount==17
  and st.ownedGateSnapshots and st.noYearLogic and st.noPostStir12
  and st.noNormativeOracleCalled,
  "PATCH27 immutable semantic evidence invalid")
 assert(ctx.stage54LegacyOctileSemanticState.source=="DISCOVERY27_OCTILE_EDGE_STICKY_PREVIOUS"
  and ctx.stage54LegacyOctileSemanticState.legacyOctileLabel==old
  and ctx.stage53PatchedQuartileSemanticState.source=="PATCH_26_QUARTILE_EDGE_EQUALITY"
  and ctx.stage53PatchedQuartileSemanticState.correctedQuartileLabel==q
  and ctx.stage52LegacyQuartileSemanticState.source=="DISCOVERY26_QUARTILE_EDGE_STICKY_PREVIOUS"
  and ctx.stage51PatchedMidpointSemanticState.source=="PATCH_25_MIDPOINT_TIE_EQUALITY"
  and ctx.stage50LegacyMidpointSemanticState.source=="DISCOVERY25_MIDPOINT_TIE_BEFORE"
  and ctx.stage49PatchedPhaseSemanticState.source=="PATCH_24_ZERO_BASED_PHASE",
  "PATCH27 historical provenance mutated")
 for i=1,18 do assert(ctx.branchTrace[i]==trace[i],"PATCH27 historical trace order") end
 ctx.stage54LegacyOctileSemanticState.legacyOctileLabel="tampered"
 ctx.stage53PatchedQuartileSemanticState.correctedQuartileLabel="tampered"
 ctx.stage52LegacyQuartileSemanticState.legacyQuartileLabel="tampered"
 ctx.stage51PatchedMidpointSemanticState.correctedMidpointLabel="tampered"
 assert(st.legacyOctileLabel==old and st.correctedQuartileLabel==q
  and st.correctedOctileLabel==right,
  "PATCH27 semantic state aliases earlier snapshots")
 return old,actual,right,edge
end
O.resetGateCache()
local rs={}
for k=-8,8 do rs[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,closings=0,0
for k=-7,7 do
 local a,b=B.from(rs[k+9].day),B.from(rs[k+10].day)
 local old,actual,right=verify(a,rs,k,a,b)
 assert(old=="E1" and actual=="E1" and right=="E1")
 openings=openings+1
 if k<=6 then
  old,actual,right=verify(B.sub(b,1),rs,k,a,b)
  assert(old=="E8" and actual=="E8" and right=="E8")
  closings=closings+1
 end
end
assert(openings==15 and closings==14)
print("PASS Stage55 canonical: 15 openings MATCH, 14 closings MATCH, 18 commits")

local repaired,flanks=0,0
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
 for boundary=1,7 do
  local anchor=B.add(a,(gap//8)*boundary)
  local old,actual,right,edge=verify(anchor,indexed,k,a,b)
  assert(old=="E"..boundary and actual=="E"..(boundary+1)
   and right==actual and edge,
   "PATCH27 boundary equality not repaired")
  repaired=repaired+1
  old,actual,right=verify(B.sub(anchor,1),indexed,k,a,b)
  assert(old==actual and actual==right and actual=="E"..boundary)
  old,actual,right=verify(B.add(anchor,1),indexed,k,a,b)
  assert(old==actual and actual==right and actual=="E"..(boundary+1))
  flanks=flanks+2
 end
end
assert(repaired==672 and flanks==1344)
print("PASS Stage55 synthetic: 672 signed BigInt octile PATCHED, 1344 flanks MATCH")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.gateOctilePatchProbe,day,records),
  "PATCH27 accepted invalid input")
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
local x,a=S.gateOctilePatchProbe(O.FOUNDATION_DAY,rs)
local y,b=S.gateOctilePatchProbe(O.FOUNDATION_DAY,rs)
assert(x==y and a~=b and a.semanticState~=b.semanticState
 and a.stage54LegacyOctileSemanticState~=b.stage54LegacyOctileSemanticState
 and a.stage53PatchedQuartileSemanticState~=b.stage53PatchedQuartileSemanticState
 and a.stage52LegacyQuartileSemanticState~=b.stage52LegacyQuartileSemanticState
 and a.stage51PatchedMidpointSemanticState~=b.stage51PatchedMidpointSemanticState
 and a.stage50LegacyMidpointSemanticState~=b.stage50LegacyMidpointSemanticState
 and a.stage49PatchedPhaseSemanticState~=b.stage49PatchedPhaseSemanticState)
a.semanticState.correctedOctileLabel="tampered"
a.stage54LegacyOctileSemanticState.legacyOctileLabel="tampered"
a.stage53PatchedQuartileSemanticState.correctedQuartileLabel="tampered"
assert(b.semanticState.correctedOctileLabel~="tampered"
 and b.stage54LegacyOctileSemanticState.legacyOctileLabel~="tampered"
 and b.stage53PatchedQuartileSemanticState.correctedQuartileLabel~="tampered")
local f=assert(io.open(root.."/src/gate_octile_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage55 hardening: 9 rejects, 2 isolated replays, Stage54 EXPECTED_RED preserved")
