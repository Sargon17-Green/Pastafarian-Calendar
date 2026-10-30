-- Stage37 PATCH18: oracle, synthetic chains, legacy scar, BigInt, ownership.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local match,corrected=0,0
local streams={}
O.resetGateCache()
for i=1,32 do
 local sauce=O.sauce(O.FOUNDATION_DAY,O.FOUNDATION_DAY-i)
 streams[i]=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 local prefix={}
 for k=1,i do prefix[k]=streams[k] end
 local right,ctx=S.negativeGatePatchProbe(i,prefix)
 local old,legacy=S.legacyNegativeGateProbe(i,prefix)
 local canonical=B.from(O.ensureGateIndex(-i))
 assert(B.compare(right,canonical)==0
  and B.compare(S.negativeGateDaySpaghetti(i,prefix),canonical)==0,
  "orak negatif pa matche n="..i)
 assert(ctx.mode=="STAGE_37_PATCH_18"
  and ctx.status=="PATCH_NEGATIVE_GATE_COMPLETE"
  and ctx.commitToken==7 and #ctx.branchTrace==7
  and ctx.branchTrace[6]=="LEGACY_NEGATIVE_GATE_RESETS_FOUNDATION"
  and ctx.branchTrace[7]=="NEGATIVE_GATE_CUMULATIVE_PATCH"
  and ctx.currentHandler=="NEGATIVE_GATE_CUMULATIVE_PATCH"
  and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil
  and #ctx.diagnostics==7
  and ctx.diagnostics[7].code=="PATCH_18_ACCUMULATE_ALL_NEGATIVE_GAPS"
  and ctx.metrics["negativeGate.patch.calls"]==1
  and ctx.metrics["legacy.negativeGate.calls"]==1
  and ctx.semanticState.source=="PATCH_18_CUMULATIVE_NEGATIVE_GATE"
  and ctx.semanticState.correctedNegativeGateDayDecimal==tostring(canonical)
  and ctx.semanticState.historicalNegativeGateDayDecimal==tostring(old)
  and ctx.semanticState.noPostStir12==true
  and ctx.legacyNegativeSemanticState.noCorrectCumulativeResultComputed==true
  and legacy.commitToken==6, "7 commits PATCH18 pa otantik")
 if i==1 then
  assert(B.compare(right,old)==0);match=match+1
 else
  assert(B.compare(right,old)<0);corrected=corrected+1
 end
 ctx.legacyNegativeSemanticState.gapDecimals[1]="tampered"
 assert(ctx.semanticState.gapDecimals[1]~="tampered",
  "eta semantic te gen alias")
end
assert(match==1 and corrected==31,"1 MATCH/31 corrected pa egzak")
print("PASS Stage37 canonical: 32 negative gates, 1 MATCH + 31 PATCHED")

local synthetic,syntheticChanged=0,0
for n=1,24 do
 for scenario=1,4 do
  local inputs,expected={},B.from(F)
  for i=1,n do
   local seed=1+((i*177+scenario*269)%920)
   local direction=(i+scenario)%2==0 and 1 or -1
   inputs[i]={first=B.from(seed),directionStep=direction}
   local gap=B.add(41,O.chooseRankShort(inputs[i],922))
   expected=B.sub(expected,gap)
  end
  local right=S.negativeGateDaySpaghetti(n,inputs)
  local wrong=S.legacyNegativeGateProbe(n,inputs)
  assert(B.compare(right,expected)==0,"synthetic gap erè")
  if n>1 then
   assert(B.compare(right,wrong)<0);syntheticChanged=syntheticChanged+1
  else assert(B.compare(right,wrong)==0) end
  synthetic=synthetic+1
 end
end
assert(synthetic==96 and syntheticChanged==92)
local a={{first=1,directionStep=1},{first=17,directionStep=-1}}
local b={{first=500,directionStep=1},{first=17,directionStep=-1}}
assert(B.compare(S.legacyNegativeGateProbe(2,a),S.legacyNegativeGateProbe(2,b))==0)
assert(B.compare(S.negativeGateDaySpaghetti(2,a),S.negativeGateDaySpaghetti(2,b))~=0)
print("PASS Stage37 synthetic: 96 chains, 92 corrections, prefix sensitivity")

local function rejects(n,s)
 local ok=pcall(S.negativeGateDaySpaghetti,n,s)
 assert(not ok,"PATCH18 invalid input not rejected")
end
rejects(0,{})
rejects(-1,{})
rejects(33,{})
rejects(2,{a[1]})
rejects(1,{{first=1,directionStep=0}})
rejects(1,{{first="not-an-integer",directionStep=1}})
rejects(1,{a[1],a[2]})
local huge=B.from("170141183460469231731687303715884105727")
local h={{first=huge,directionStep=1},{first=B.sub(huge,999),directionStep=-1}}
local p1,c1=S.negativeGatePatchProbe(2,h)
local p2,c2=S.negativeGatePatchProbe(2,h)
assert(B.compare(p1,p2)==0 and c1~=c2
 and c1.semanticState~=c2.semanticState
 and c1.gapSourceStates[1]~=c2.gapSourceStates[1])
local source=assert(io.open(root.."/src/negative_gate_patch.lua","rb"))
local code=source:read("*a");source:close()
assert(not code:find('require("normative_oracle")',1,true))
print("PASS Stage37 hardening: 7 rejects, two BigInt replays, independent owned state")
