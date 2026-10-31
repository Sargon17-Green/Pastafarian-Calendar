-- Stage42 DISCOVERY21: independently test intentionally wrong reverse ordinal.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle") -- test-only independent canonical gates
local S=require("spaghetti")
local cmp=B.compare
local function copy(rs)
 local out={}
 for i=1,#rs do out[i]={index=rs[i].index,day=tostring(rs[i].day)} end
 return out
end
local function verify(day,records,k,closing)
 local legacy,ctx=S.legacyGateReverseOrdinalProbe(day,records)
 local oracle=B.sub(closing,day) -- independent direct closing boundary minus day
 assert(cmp(B.add(legacy,1),oracle)==0 and cmp(legacy,oracle)~=0,
  "DISCOVERY21: expected-red witness not reproduced")
 assert(ctx.mode=="STAGE_42_DISCOVERY_21"
  and ctx.status=="LEGACY_GATE_REVERSE_ORDINAL_COMPLETE"
  and ctx.commitToken==5 and #ctx.branchTrace==5
  and ctx.branchTrace[1]=="LEGACY_GATE_INDEX_STRICT_LT"
  and ctx.branchTrace[2]=="GATE_INDEX_LEQ_BOUNDARY_PATCH"
  and ctx.branchTrace[3]=="LEGACY_GATE_ORDINAL_ZERO_BASED"
  and ctx.branchTrace[4]=="GATE_ORDINAL_ONE_BASED_PATCH"
  and ctx.branchTrace[5]=="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
  and ctx.currentHandler=="LEGACY_REVERSE_ORDINAL_EXCLUDES_TODAY"
  and #ctx.diagnostics==5
  and ctx.diagnostics[5].code=="DISCOVERY21_REVERSE_ORDINAL_EXCLUDES_CURRENT_DAY"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and ctx.metrics["discovery21.legacy.reverse.lookups"]==1
  and ctx.stage41GateOrdinalSemanticState.correctedGateIndex==k
  and ctx.semanticState.correctedGateIndex==k
  and ctx.semanticState.excludesCurrentDay==true
  and ctx.semanticState.noCanonicalReverseOrdinalComputed==true
  and ctx.semanticState.preservedHistoricalCommitCount==4
  and ctx.semanticState.noYearLogic and ctx.semanticState.noPostStir12
  and cmp(ctx.semanticState.historicalReverseOrdinalDecimal,legacy)==0,
  "DISCOVERY21: ownership and five-commit trace invalid")
 return legacy,ctx
end
O.resetGateCache()
local gates={}
for k=-8,8 do gates[k+9]={index=k,day=tostring(O.ensureGateIndex(k))} end
local opening,closingWitnesses=0,0
for k=-7,7 do
 local start=B.from(gates[k+9].day)
 local closing=B.from(gates[k+10].day)
 local gap=B.sub(closing,start)
 local atStart,ctx=verify(start,gates,k,closing)
 assert(cmp(atStart,B.sub(gap,1))==0)
 ctx.semanticState.historicalReverseOrdinalDecimal="tampered"
 assert(cmp(ctx.stage41GateOrdinalSemanticState.correctedOrdinalDecimal,1)==0)
 opening=opening+1
 local last=B.sub(closing,1)
 local atEnd=verify(last,gates,k,closing)
 assert(cmp(atEnd,0)==0 and cmp(B.sub(closing,last),1)==0)
 closingWitnesses=closingWitnesses+1
end
assert(opening==15 and closingWitnesses==15)
print("PASS Stage42 canonical: 15 opening + 15 closing reverse-ordinal expected-RED")

local synthetic=0
for scenario=1,96 do
 local center=B.from("170141183460469231731687303715884105727")
 if scenario%2==0 then center=B.neg(center) end
 center=B.add(center,scenario)
 local days={[9]=center}
 for n=1,8 do
  days[9-n]=B.sub(days[10-n],42+((n*41+scenario*37)%922))
  days[9+n]=B.add(days[8+n],42+((n*79+scenario*23)%922))
 end
 local records={}
 for k=-8,8 do records[k+9]={index=k,day=tostring(days[k+9])} end
 local k=-7+(scenario%15)
 local closing=days[k+10]
 local last=B.sub(closing,1)
 local val,ctx=verify(last,records,k,closing)
 assert(cmp(val,0)==0 and cmp(ctx.semanticState.stage41CorrectedOrdinalDecimal,
  B.sub(closing,days[k+9]))==0)
 synthetic=synthetic+1
end
assert(synthetic==96)
print("PASS Stage42 synthetic: 96 signed BigInt reverse-ordinal expected-RED")

local rejected=0
local function reject(day,records)
 assert(not pcall(S.legacyGateReverseOrdinalProbe,day,records),
  "DISCOVERY21: malformed input unexpectedly accepted")
 rejected=rejected+1
end
reject("invalid",gates)
reject(B.sub(gates[2].day,1),gates)
reject(B.add(gates[17].day,1),gates)
local t=copy(gates);table.remove(t,1);reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[9].day=t[8].day;reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[9].index=20;reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[10].day=tostring(B.add(t[9].day,1000000));reject(O.FOUNDATION_DAY,t)
t=copy(gates);t.extra="bad";reject(O.FOUNDATION_DAY,t)
t=copy(gates);t[5].day="invalid";reject(O.FOUNDATION_DAY,t)
assert(rejected==9)
local a,first=S.legacyGateReverseOrdinalProbe(O.FOUNDATION_DAY,gates)
local b,second=S.legacyGateReverseOrdinalProbe(O.FOUNDATION_DAY,gates)
assert(cmp(a,b)==0 and first~=second
 and first.semanticState~=second.semanticState
 and first.stage41GateOrdinalSemanticState~=second.stage41GateOrdinalSemanticState)
first.stage41GateOrdinalSemanticState.correctedOrdinalDecimal="tampered"
first.semanticState.historicalReverseOrdinalDecimal="tampered"
assert(second.semanticState.historicalReverseOrdinalDecimal~="tampered"
 and second.stage41GateOrdinalSemanticState.correctedOrdinalDecimal~="tampered")
local f=assert(io.open(root.."/src/legacy_gate_reverse_ordinal.lua","rb"))
local code=f:read("*a");f:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage42 hardening: 9 rejects, 2 isolated replays, no oracle in production")
