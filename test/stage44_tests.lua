-- Stage44/DISCOVERY22: independent nearest-boundary test-only oracle.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local cmp=B.compare
local function copy(records)
 local out={}
 for i=1,#records do out[i]={index=records[i].index,day=tostring(records[i].day)} end
 return out
end
local function verify(day,records,k,a,b,wantRed)
 local old,ctx=S.legacyGateNearestBoundaryProbe(day,records)
 -- Oracle uses only raw records and target; no production ordinal or state.
 local expected=cmp(B.sub(day,a),B.sub(b,day))<=0 and "OPENING" or "CLOSING"
 assert((old~=expected)==wantRed,"DISCOVERY22: red/match mismatch")
 assert(ctx.mode=="STAGE_44_DISCOVERY_22"
  and ctx.status=="LEGACY_NEAREST_GATE_COMPLETE"
  and ctx.commitToken==7 and #ctx.branchTrace==7
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.branchTrace[4]=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.branchTrace[5]=="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
  and ctx.branchTrace[6]=="GATE_REVERSE_ORDINAL_INCLUSIVE_PATCH"
  and ctx.branchTrace[7]=="LEGACY_NEAREST_GATE_ONEBASED_TIE"
  and ctx.currentHandler=="LEGACY_NEAREST_GATE_ONEBASED_TIE"
  and #ctx.diagnostics==7
  and ctx.diagnostics[7].code=="DISCOVERY22_ONEBASED_NEAREST_GATE_TIE"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["discovery22.legacy.nearest.lookups"]==1
  and ctx.metrics["patch21.inclusive.reverse.lookups"]==1
  and ctx.stage43ReverseOrdinalSemanticState.includesCurrentDay==true
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.oneBasedOrdinalComparedToDistance==true
  and ctx.semanticState.noCanonicalNearestGateComputed==true
  and ctx.semanticState.preservedHistoricalCommitCount==6
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and ctx.semanticState.historicalNearestGate==old)
 ctx.stage43ReverseOrdinalSemanticState.correctedReverseOrdinalDecimal="tampered"
 assert(ctx.semanticState.stage43CorrectedReverseOrdinalDecimal~="tampered")
 return old,expected
end
O.resetGateCache()
local records={}
for k=-8,8 do records[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local openings,middles,finals=0,0,0
for k=-7,7 do
 local a=B.from(records[k+9].day)
 local b=B.from(records[k+10].day)
 local gap=assert(B.toNumber(B.sub(b,a)))
 local old,expected=verify(a,records,k,a,b,false)
 assert(old=="OPENING" and expected=="OPENING")
 openings=openings+1
 if k<=6 then
  local middle=B.add(a,math.floor(gap/2))
  local even=gap%2==0
  local observed,ideal=verify(middle,records,k,a,b,even)
  assert(ideal=="OPENING")
  if even then assert(observed=="CLOSING") end
  middles=middles+1
  local tail,truth=verify(B.sub(b,1),records,k,a,b,false)
  assert(tail=="CLOSING" and truth=="CLOSING")
  finals=finals+1
 end
end
assert(openings==15 and middles==14 and finals==14)
print("PASS Stage44 canonical: 15 openings, 14 midpoint probes, 14 final days, parity-aware expected-RED")
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
 local actual,ideal=verify(B.add(a,gap//2),rs,k,a,b,true)
 assert(actual=="CLOSING" and ideal=="OPENING")
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage44 synthetic: 96 signed BigInt even-gap midpoint EXPECTED_RED")
local rejects=0
local function reject(d,rs)
 assert(not pcall(S.legacyGateNearestBoundaryProbe,d,rs))
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
local one,first=S.legacyGateNearestBoundaryProbe(O.FOUNDATION_DAY,records)
local two,second=S.legacyGateNearestBoundaryProbe(O.FOUNDATION_DAY,records)
assert(one==two and first~=second and first.semanticState~=second.semanticState
 and first.stage43ReverseOrdinalSemanticState~=second.stage43ReverseOrdinalSemanticState)
first.semanticState.historicalNearestGate="tampered"
first.stage43ReverseOrdinalSemanticState.correctedReverseOrdinalDecimal="tampered"
assert(second.semanticState.historicalNearestGate~="tampered"
 and second.stage43ReverseOrdinalSemanticState.correctedReverseOrdinalDecimal~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_nearest_boundary.lua","rb"))
local source=f:read("*a");f:close()
assert(not source:find('require("normative_oracle")',1,true))
print("PASS Stage44 hardening: 9 rejects, 2 isolated replays, no oracle in production")
