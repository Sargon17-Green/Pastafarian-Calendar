-- Stage39 / PATCH19: independent oracle, legacy trace, BigInt and rejection.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local function cmp(a,b) return B.compare(a,b) end
local function prefix(xs,n)
 local out={}
 for i=1,n do out[i]=xs[i] end
 return out
end
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
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
 assert(cmp(day,O.ensureGateIndex(k))==0,"PATCH17/PATCH18 gate mismatch")
 gates[k+9]={index=k,day=tostring(day)}
end

local fixed,interior=0,0
for k=-7,7 do
 local day=O.ensureGateIndex(k)
 local old,legacy=S.legacyGateIndexProbe(day,gates)
 local right,ctx=S.gateIndexPatchProbe(day,gates)
 assert(old==k-1 and right==k and O.gateIndexAtOrBefore(day)==k,
  "Stage39 exact boundary not repaired")
 assert(ctx.mode=="STAGE_39_PATCH_19"
  and ctx.status=="PATCH_GATE_INDEX_COMPLETE"
  and ctx.commitToken==2 and #ctx.branchTrace==2
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.currentHandler=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==2
  and ctx.diagnostics[2].code=="PATCH19_STRICT_LT_TO_LEQ_BOUNDARY"
  and ctx.metrics["discovery19.legacy.lookups"]==1
  and ctx.metrics["patch19.boundary.lookups"]==1
  and ctx.legacyGateIndexSemanticState.strictLessInsteadOfLessOrEqual==true
  and ctx.legacyGateIndexSemanticState.returnedIndex==old
  and ctx.legacyGateIndex==old
  and ctx.semanticState.source=="PATCH_19_GATE_INDEX_AT_OR_BEFORE"
  and ctx.semanticState.exactBoundaryCorrected==true
  and ctx.semanticState.correctedIndex==right
  and legacy.commitToken==1,
  "Stage39 must preserve legacy and append one semantic commit")
 ctx.legacyGateIndexSemanticState.gateDayDecimals[1]="tampered"
 assert(ctx.semanticState.gateDayDecimals[1]~="tampered",
  "Stage39 semantic snapshots alias")
 fixed=fixed+1
 if k<=6 then
  local dayInside=B.add(day,1)
  local historical=S.legacyGateIndexProbe(dayInside,gates)
  local actual,state=S.gateIndexPatchProbe(dayInside,gates)
  assert(O.gateIndexAtOrBefore(dayInside)==k
   and historical==k and actual==k
   and state.semanticState.exactBoundaryCorrected==false,
   "Stage39 interior cannot shift index")
  interior=interior+1
 end
end
assert(fixed==15 and interior==14)
print("PASS Stage39 canonical: 15 boundary corrections, 14 interior matches, legacy scar kept")

local synthetic=0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=B.from(center)}
 for n=1,8 do
  local left=42+((n*41+scenario*37)%922)
  local right=42+((n*79+scenario*23)%922)
  days[9-n]=B.sub(days[10-n],left)
  days[9+n]=B.add(days[8+n],right)
 end
 local records={}
 for k=-8,8 do records[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%14)
 local exact=days[k+9]
 local corrected,ctx=S.gateIndexPatchProbe(exact,records)
 local inside,insideCtx=S.gateIndexPatchProbe(B.add(exact,1),records)
 assert(corrected==k and inside==k
  and ctx.legacyGateIndex==k-1 and ctx.semanticState.exactBoundaryCorrected
  and insideCtx.legacyGateIndex==k
  and insideCtx.semanticState.exactBoundaryCorrected==false
  and cmp(ctx.semanticState.gateDayDecimals[k+9],exact)==0
  and records[k+9].day==tostring(exact),
  "Stage39 synthetic boundary and interior mismatch")
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage39 synthetic: 96 BigInt chains, 96 exact corrections, 96 interior matches")

local rejects=0
local function reject(day,records)
 assert(not pcall(S.gateIndexPatchProbe,day,records),
  "Stage39 must reject invalid source")
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
local a,ca=S.gateIndexPatchProbe(F,gates)
local b,cb=S.gateIndexPatchProbe(F,gates)
assert(a==0 and b==0 and ca~=cb
 and ca.semanticState~=cb.semanticState
 and ca.legacyGateIndexSemanticState~=cb.legacyGateIndexSemanticState
 and ca.semanticState.gateDayDecimals~=cb.semanticState.gateDayDecimals)
ca.semanticState.gateDayDecimals[1]="tampered"
assert(cb.semanticState.gateDayDecimals[1]~="tampered")
local f=assert(io.open(root.."/src/gate_index_patch.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
assert(rejects==9)
print("PASS Stage39 hardening: 9 rejects, 2 owned replays, no oracle in production")
