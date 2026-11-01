-- Stage47/PATCH23: independent raw-distance oracle; Stage46 historical audit.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- test-only gate generation
local S=require("spaghetti")
local cmp=B.compare
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET","GATE_SIGNED_OFFSET_DIRECTION_PATCH"
}
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return out
end
local function verify(day,rs,k,a,b)
 local old,hctx=S.legacyGateSignedOffsetProbe(day,rs)
 local patched,ctx=S.gateSignedOffsetPatchProbe(day,rs)
 local left,right=B.sub(day,a),B.sub(b,day)
 local choice=cmp(left,right)<=0 and "OPENING" or "CLOSING"
 local magnitude=choice=="OPENING" and left or right
 local expected=choice=="OPENING" and left or B.neg(right)
 assert(cmp(old,magnitude)==0 and cmp(patched,expected)==0
  and ((cmp(old,expected)~=0)==(choice=="CLOSING")),
  "PATCH23: wrong signed offset or historical EXPECTED_RED witness")
 assert(hctx.mode=="STAGE_46_DISCOVERY_23"
  and hctx.status=="LEGACY_SIGNED_OFFSET_COMPLETE"
  and hctx.commitToken==9 and #hctx.branchTrace==9
  and hctx.semanticState.discardsClosingDirection==true,
  "PATCH23: Stage46 historical context changed")
 assert(ctx.mode=="STAGE_47_PATCH_23"
  and ctx.status=="PATCH_SIGNED_OFFSET_COMPLETE"
  and ctx.commitToken==10 and #ctx.branchTrace==10
  and ctx.currentHandler=="GATE_SIGNED_OFFSET_DIRECTION_PATCH"
  and #ctx.diagnostics==10
  and ctx.diagnostics[9].code=="DISCOVERY23_CLOSING_DIRECTION_LOST"
  and ctx.diagnostics[10].code=="PATCH23_CLOSING_DIRECTION_RESTORED"
  and ctx.metrics["patch23.signed.offsets"]==1
  and ctx.metrics["discovery23.legacy.unsigned.offsets"]==1
  and ctx.metrics["patch22.nearest.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.legacyUnsignedGateOffsetDecimal==tostring(magnitude)
  and ctx.stage46SignedOffsetSemanticState.historicalUnsignedOffsetDecimal==tostring(magnitude)
  and ctx.stage46SignedOffsetSemanticState.discardsClosingDirection==true
  and ctx.stage45NearestBoundarySemanticState.midpointTieToOpening==true
  and ctx.semanticState.source=="PATCH_23_NEAREST_GATE_SIGNED_OFFSET"
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.correctedNearestGate==choice
  and ctx.semanticState.correctedSignedOffsetDecimal==tostring(expected)
  and ctx.semanticState.historicalUnsignedOffsetDecimal==tostring(magnitude)
  and ctx.semanticState.preservedHistoricalCommitCount==9
  and ctx.semanticState.closingDirectionRestored==true
  and ctx.semanticState.zeroCanonical==true
  and ctx.semanticState.midpointTieToOpening==true
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.noNormativeOracleCalled==true,
  "PATCH23: trace, metrics, or signed-state provenance invalid")
 for i=1,10 do assert(ctx.branchTrace[i]==trace[i],"PATCH23: trace order changed") end
 ctx.stage46SignedOffsetSemanticState.correctedNearestGate="tampered"
 ctx.stage45NearestBoundarySemanticState.correctedNearestGate="tampered"
 assert(ctx.semanticState.correctedNearestGate==choice)
 return patched,old,choice
end
O.resetGateCache()
local records={}
for k=-8,8 do records[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,middles,closings=0,0,0
for k=-7,7 do
 local a,b=B.from(records[k+9].day),B.from(records[k+10].day)
 local gap=assert(B.toNumber(B.sub(b,a)))
 local output,old,choice=verify(a,records,k,a,b)
 assert(choice=="OPENING" and cmp(output,0)==0 and cmp(old,0)==0)
 openings=openings+1
 if k<=6 then
  local mid=B.add(a,math.floor(gap/2))
  output,old,choice=verify(mid,records,k,a,b)
  assert(choice=="OPENING" and cmp(output,B.sub(mid,a))==0 and cmp(old,output)==0)
  middles=middles+1
  output,old,choice=verify(B.sub(b,1),records,k,a,b)
  assert(choice=="CLOSING" and cmp(output,-1)==0 and cmp(old,1)==0)
  closings=closings+1
 end
end
assert(openings==15 and middles==14 and closings==14)
print("PASS Stage47 canonical: 15 opening MATCH, 14 midpoint MATCH, 14 closing PATCHED, 10 commits")
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
 local rs={}
 for k=-8,8 do rs[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local a,b=days[k+9],days[k+10]
 local gap=assert(B.toNumber(B.sub(b,a)))
 assert(gap>=42 and gap<=962 and gap%2==0)
 local requested=B.sub(b,2+(scenario%5))
 local output,old,choice=verify(requested,rs,k,a,b)
 assert(choice=="CLOSING"
  and cmp(output,B.neg(B.sub(b,requested)))==0
  and cmp(old,B.sub(b,requested))==0)
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage47 synthetic: 96 signed BigInt closing-direction PATCHED")
local rejects=0
local function reject(day,rs)
 assert(not pcall(S.gateSignedOffsetPatchProbe,day,rs),
  "PATCH23: malformed or out-of-window input accepted")
 rejects=rejects+1
end
reject("invalid",records)
reject(B.sub(records[2].day,1),records)
reject(B.sub(records[17].day,1),records)
local t=copy(records);table.remove(t,1);reject(O.FOUNDATION_DAY,t)
t=copy(records);t[9].day=t[8].day;reject(O.FOUNDATION_DAY,t)
t=copy(records);t[9].index=20;reject(O.FOUNDATION_DAY,t)
t=copy(records);t[10].day=tostring(B.add(t[9].day,1000000));reject(O.FOUNDATION_DAY,t)
t=copy(records);t.extra="bad";reject(O.FOUNDATION_DAY,t)
t=copy(records);t[5].day="invalid";reject(O.FOUNDATION_DAY,t)
assert(rejects==9)
local x,first=S.gateSignedOffsetPatchProbe(O.FOUNDATION_DAY,records)
local y,second=S.gateSignedOffsetPatchProbe(O.FOUNDATION_DAY,records)
assert(x==y and first~=second and first.semanticState~=second.semanticState
 and first.stage46SignedOffsetSemanticState~=second.stage46SignedOffsetSemanticState
 and first.stage45NearestBoundarySemanticState~=second.stage45NearestBoundarySemanticState)
first.semanticState.correctedNearestGate="tampered"
first.stage46SignedOffsetSemanticState.correctedNearestGate="tampered"
first.stage45NearestBoundarySemanticState.correctedNearestGate="tampered"
assert(second.semanticState.correctedNearestGate~="tampered"
 and second.stage46SignedOffsetSemanticState.correctedNearestGate~="tampered"
 and second.stage45NearestBoundarySemanticState.correctedNearestGate~="tampered")
local f=assert(io.open(root.."/src/gate_signed_offset_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage47 hardening: 9 rejects, 2 isolated replays, no oracle in production")
