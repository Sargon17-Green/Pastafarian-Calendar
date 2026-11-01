-- Stage46/DISCOVERY23: signed offset from independently supplied gate records.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- test-only canonical gate generator
local S=require("spaghetti")
local cmp=B.compare
local expectedTrace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH",
 "LEGACY_UNSIGNED_NEAREST_GATE_OFFSET"
}
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return out
end
local function verify(day,records,k,a,b,wantRed)
 -- Independent test oracle: compare raw distances; negative means next gate.
 local left=B.sub(day,a)
 local right=B.sub(b,day)
 local choice=cmp(left,right)<=0 and "OPENING" or "CLOSING"
 local signed=choice=="OPENING" and left or B.neg(right)
 local output,ctx=S.legacyGateSignedOffsetProbe(day,records)
 assert(cmp(output,signed)~=(0)==wantRed,
  "DISCOVERY23: expected-RED/MATCH against independent signed oracle")
 local magnitude=choice=="OPENING" and left or right
 assert(cmp(output,magnitude)==0,
  "DISCOVERY23: historical magnitude altered")
 assert(ctx.mode=="STAGE_46_DISCOVERY_23"
  and ctx.status=="LEGACY_SIGNED_OFFSET_COMPLETE"
  and ctx.commitToken==9 and #ctx.branchTrace==9
  and ctx.currentHandler=="LEGACY_UNSIGNED_NEAREST_GATE_OFFSET"
  and #ctx.diagnostics==9
  and ctx.diagnostics[9].code=="DISCOVERY23_CLOSING_DIRECTION_LOST"
  and ctx.metrics["discovery23.legacy.unsigned.offsets"]==1
  and ctx.metrics["patch22.nearest.lookups"]==1
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.semanticState.source=="DISCOVERY23_UNSIGNED_NEAREST_GATE_OFFSET"
  and ctx.semanticState.discardsClosingDirection==true
  and ctx.semanticState.noCanonicalSignedOffsetComputed==true
  and ctx.semanticState.preservedHistoricalCommitCount==8
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.correctedNearestGate==choice
  and ctx.stage45NearestBoundarySemanticState.correctedNearestGate==choice
  and ctx.stage45NearestBoundarySemanticState.midpointTieToOpening==true
  and ctx.stage44NearestBoundarySemanticState.oneBasedOrdinalComparedToDistance==true
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.noNormativeOracleCalled)
 for i=1,9 do assert(ctx.branchTrace[i]==expectedTrace[i],"DISCOVERY23: trace changed") end
 ctx.stage45NearestBoundarySemanticState.correctedNearestGate="tampered"
 assert(ctx.semanticState.correctedNearestGate==choice)
 return output,choice,ctx
end
O.resetGateCache()
local records={}
for k=-8,8 do records[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,middles,closings=0,0,0
for k=-7,7 do
 local a,b=B.from(records[k+9].day),B.from(records[k+10].day)
 local gap=assert(B.toNumber(B.sub(b,a)))
 local first,choice=verify(a,records,k,a,b,false)
 assert(cmp(first,0)==0 and choice=="OPENING");openings=openings+1
 if k<=6 then
  local mid=B.add(a,math.floor(gap/2))
  local m,mc=verify(mid,records,k,a,b,false)
  assert(mc=="OPENING" and cmp(m,B.sub(mid,a))==0)
  middles=middles+1
  local last,lc=verify(B.sub(b,1),records,k,a,b,true)
  assert(lc=="CLOSING" and cmp(last,1)==0)
  closings=closings+1
 end
end
assert(openings==15 and middles==14 and closings==14)
print("PASS Stage46 canonical: 15 opening MATCH, 14 midpoint MATCH, 14 closing EXPECTED_RED, 9 commits")
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
 local actual,choice=verify(requested,rs,k,a,b,true)
 assert(choice=="CLOSING" and cmp(actual,B.sub(b,requested))==0)
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage46 synthetic: 96 signed BigInt closing-direction EXPECTED_RED")
local rejects=0
local function reject(day,rs)
 assert(not pcall(S.legacyGateSignedOffsetProbe,day,rs),
  "DISCOVERY23: malformed or out-of-window input accepted")
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
local x,first=S.legacyGateSignedOffsetProbe(O.FOUNDATION_DAY,records)
local y,second=S.legacyGateSignedOffsetProbe(O.FOUNDATION_DAY,records)
assert(x==y and first~=second and first.semanticState~=second.semanticState
 and first.stage45NearestBoundarySemanticState~=second.stage45NearestBoundarySemanticState
 and first.stage44NearestBoundarySemanticState~=second.stage44NearestBoundarySemanticState)
first.semanticState.correctedNearestGate="tampered"
first.stage45NearestBoundarySemanticState.correctedNearestGate="tampered"
assert(second.semanticState.correctedNearestGate~="tampered"
 and second.stage45NearestBoundarySemanticState.correctedNearestGate~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_signed_offset.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage46 hardening: 9 rejects, 2 isolated replays, no oracle in production")
