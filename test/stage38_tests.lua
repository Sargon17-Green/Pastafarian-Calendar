-- Stage38 Native: independent canonical gate oracle and intentional RED witness.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local function cmp(a,b) return B.compare(a,b) end
local function prefix(input,n)
 local out={}
 for i=1,n do out[i]=input[i] end
 return out
end
local function copy(records)
 local out={}
 for i=1,#records do
  out[i]={index=records[i].index,day=tostring(records[i].day)}
 end
 return out
end

O.resetGateCache()
local pos,neg={},{}
for n=1,8 do
 pos[n]=O.askBowl(O.sauce(F,F+n),1,O.SEAL_GATE_GAP)
 neg[n]=O.askBowl(O.sauce(F,F-n),1,O.SEAL_GATE_GAP)
end
local gates={}
for k=-8,8 do
 local day
 if k<0 then day=S.negativeGateDaySpaghetti(-k,prefix(neg,-k))
 elseif k>0 then day=S.positiveGateDaySpaghetti(k,prefix(pos,k))
 else day=B.from(F) end
 assert(cmp(day,O.ensureGateIndex(k))==0,"signed PATCH sources mismatch")
 gates[k+9]={index=k,day=tostring(day)}
end
local red,match=0,0
for k=-7,7 do
 local day=O.ensureGateIndex(k)
 local historical,ctx=S.legacyGateIndexProbe(day,gates)
 assert(O.gateIndexAtOrBefore(day)==k and historical==k-1,
  "exact gate must expose intentional strict-LT defect")
 assert(ctx.mode=="STAGE_38_DISCOVERY_19"
  and ctx.status=="LEGACY_GATE_INDEX_COMPLETE"
  and ctx.commitToken==1 and #ctx.branchTrace==1
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.currentHandler=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.semanticState.source=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.semanticState.noCanonicalLookupComputed
  and ctx.semanticState.noPostStir12 and ctx.semanticState.noYearLogic
  and #ctx.semanticState.gateDayDecimals==17
  and ctx.metrics["discovery19.legacy.lookups"]==1,
  "Stage38 semantic context not owned/committed")
 red=red+1
 if k<=6 then
  local interior=day+1
  assert(O.gateIndexAtOrBefore(interior)==k,
   "independent canonical interior mismatch")
  assert(S.legacyGateIndexProbe(interior,gates)==k,
   "legacy interior should match")
  match=match+1
 end
end
assert(red==15 and match==14)
print("PASS Stage38 canonical: 15 exact EXPECTED_RED, 14 interior MATCH, Stage37 sources unchanged")

local synthetic=0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=B.from(center)}
 for n=1,8 do
  local leftGap=42+((n*41+scenario*37)%922)
  local rightGap=42+((n*79+scenario*23)%922)
  days[9-n]=B.sub(days[10-n],leftGap)
  days[9+n]=B.add(days[8+n],rightGap)
 end
 local records={}
 for k=-8,8 do records[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local exact=days[k+9]
 local historical,ctx=S.legacyGateIndexProbe(exact,records)
 assert(historical==k-1
   and S.legacyGateIndexProbe(B.add(exact,1),records)==k,
   "synthetic BigInt legacy boundary/interior mismatch")
 assert(cmp(ctx.semanticState.gateDayDecimals[k+9],exact)==0
   and records[k+9].day==tostring(exact),
   "input unexpectedly mutated")
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage38 synthetic: 96 BigInt chains, 96 boundary RED, 96 interior MATCH")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.legacyGateIndexProbe,day,records),
  "invalid input must be rejected")
 rejects=rejects+1
end
reject("not-integer",gates)
reject(B.sub(gates[2].day,1),gates)
reject(B.add(gates[16].day,1),gates)
local r=copy(gates);table.remove(r,1);reject(F,r)
r=copy(gates);r[9].day=r[8].day;reject(F,r)
r=copy(gates);r[9].index=20;reject(F,r)
r=copy(gates);r[10].day=tostring(B.add(r[9].day,1000000));reject(F,r)
r=copy(gates);r.extra="bad";reject(F,r)
r=copy(gates);r[5].day="invalid";reject(F,r)
local first,c1=S.legacyGateIndexProbe(F,gates)
local second,c2=S.legacyGateIndexProbe(F,gates)
assert(first==-1 and second==-1 and c1~=c2
 and c1.semanticState~=c2.semanticState
 and c1.semanticState.gateDayDecimals~=c2.semanticState.gateDayDecimals)
c1.semanticState.gateDayDecimals[1]="tampered"
assert(c2.semanticState.gateDayDecimals[1]~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_index_lookup.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
assert(rejects==9)
print("PASS Stage38 hardening: 9 rejects, owned snapshots, no oracle in production")
