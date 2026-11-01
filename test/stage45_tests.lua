-- Stage45/PATCH22: direct independent nearest-boundary oracle and historic Stage44 audit.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- only tests may construct canonical gates
local S=require("spaghetti")
local cmp=B.compare
local trace={
 "LEGACY_GATE_INDEX_STRICT_LT","GATE_INDEX_LEQ_BOUNDARY_PATCH",
 "LEGACY_GATE_ORDINAL_ZERO_BASED","GATE_ORDINAL_ONE_BASED_PATCH",
 "LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY","GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH",
 "LEGACY_NEAREST_GATE_ONEBASED_TIE","GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH"
}
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return out
end
local function verify(day,records,k,a,b,wantRed)
 local historic,hctx=S.legacyGateNearestBoundaryProbe(day,records)
 local corrected,ctx=S.gateNearestBoundaryPatchProbe(day,records)
 local left,right=B.sub(day,a),B.sub(b,day)
 local expected=cmp(left,right)<=0 and "OPENING" or "CLOSING"
 assert(corrected==expected and ((historic~=expected)==wantRed),
  "PATCH22: mismatch against independent distance oracle")
 assert(hctx.commitToken==7 and #hctx.branchTrace==7
  and hctx.status=="LEGACY_NEAREST_GATE_COMPLETE"
  and hctx.semanticState.oneBasedOrdinalComparedToDistance==true,
  "PATCH22: Stage44 historical probe no longer authentic")
 assert(ctx.mode=="STAGE_45_PATCH_22"
  and ctx.status=="PATCH_NEAREST_GATE_COMPLETE"
  and ctx.commitToken==8 and #ctx.branchTrace==8
  and ctx.currentHandler=="GATE_NEAREST_BOUNDARY_MIDPOINT_PATCH"
  and #ctx.diagnostics==8
  and ctx.diagnostics[7].code=="DISCOVERY22_ONEBASED_NEAREST_GATE_TIE"
  and ctx.diagnostics[8].code=="PATCH22_NEAREST_GATE_MIDPOINT_TIE_TO_OPENING"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["discovery22.legacy.nearest.lookups"]==1
  and ctx.metrics["patch22.nearest.lookups"]==1
  and ctx.metrics["patch21.inclusive.reverse.lookups"]==1
  and ctx.stage44NearestBoundarySemanticState.historicalNearestGate==historic
  and ctx.stage44NearestBoundarySemanticState.preservedHistoricalCommitCount==6
  and ctx.semanticState.historicalNearestGate==historic
  and ctx.semanticState.correctedNearestGate==expected
  and ctx.semanticState.midpointTieToOpening==true
  and ctx.semanticState.preservedHistoricalCommitCount==7
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.noNormativeOracleCalled==true
  and ctx.legacyGateNearestBoundaryChoice==historic)
 for i=1,8 do assert(ctx.branchTrace[i]==trace[i],"PATCH22: reordered trace") end
 assert(cmp(ctx.semanticState.openingDistanceDecimal,left)==0
  and cmp(ctx.semanticState.closingDistanceDecimal,right)==0)
 ctx.stage44NearestBoundarySemanticState.historicalNearestGate="tampered"
 assert(ctx.semanticState.historicalNearestGate==historic)
 return corrected,historic,ctx
end
O.resetGateCache()
local records={}
for k=-8,8 do records[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,middles,finals,correctedTies=0,0,0,0
for k=-7,7 do
 local a=B.from(records[k+9].day)
 local b=B.from(records[k+10].day)
 local gap=assert(B.toNumber(B.sub(b,a)))
 local first=verify(a,records,k,a,b,false)
 assert(first=="OPENING");openings=openings+1
 if k<=6 then
  local atMid=B.add(a,math.floor(gap/2))
  local even=(gap%2==0)
  local choice,old=verify(atMid,records,k,a,b,even)
  assert(choice=="OPENING")
  if even then assert(old=="CLOSING");correctedTies=correctedTies+1 end
  middles=middles+1
  local final=verify(B.sub(b,1),records,k,a,b,false)
  assert(final=="CLOSING");finals=finals+1
 end
end
assert(openings==15 and middles==14 and finals==14)
print("PASS Stage45 canonical: 15 openings, 14 midpoints, 14 final days, parity-aware tie repairs, 8 commits")
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
 local correct,legacy=verify(B.add(a,gap//2),rs,k,a,b,true)
 assert(correct=="OPENING" and legacy=="CLOSING")
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage45 synthetic: 96 signed BigInt even-gap midpoint corrections")
local rejects=0
local function reject(day,rs)
 assert(not pcall(S.gateNearestBoundaryPatchProbe,day,rs),
  "PATCH22: malformed or out-of-window input accepted")
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
local x,first=S.gateNearestBoundaryPatchProbe(O.FOUNDATION_DAY,records)
local y,second=S.gateNearestBoundaryPatchProbe(O.FOUNDATION_DAY,records)
assert(x==y and first~=second and first.semanticState~=second.semanticState
 and first.stage44NearestBoundarySemanticState~=second.stage44NearestBoundarySemanticState
 and first.stage43ReverseOrdinalSemanticState~=second.stage43ReverseOrdinalSemanticState)
first.semanticState.correctedNearestGate="tampered"
first.stage44NearestBoundarySemanticState.historicalNearestGate="tampered"
assert(second.semanticState.correctedNearestGate~="tampered"
 and second.stage44NearestBoundarySemanticState.historicalNearestGate~="tampered")
local f=assert(io.open(root.."/src/gate_nearest_boundary_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage45 hardening: 9 rejects, 2 isolated replays, no oracle in production")
