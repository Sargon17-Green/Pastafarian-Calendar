-- Native Stage36: canonical negative oracle and intentional legacy divergence.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local S=require("spaghetti")
local B=require("bigint")
local O=require("normative_oracle")
local F=B.from(O.FOUNDATION_DAY)
local streams,gaps={},{}
O.resetGateCache()
for i=1,32 do
 local sauce=O.sauce(O.FOUNDATION_DAY,O.FOUNDATION_DAY-i)
 streams[i]=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 gaps[i]=B.add(41,O.chooseRank(streams[i],B.from(922)))
 assert(B.compare(gaps[i],B.from(42))>=0 and B.compare(gaps[i],B.from(963))<=0,
  "gap orak negatif soti nan limit")
end
local matches,reds=0,0
local cumulative=B.from(F)
for n=1,32 do
 cumulative=B.sub(cumulative,gaps[n])
 local prefix={}
 for i=1,n do prefix[i]=streams[i] end
 local old,ctx=S.legacyNegativeGateProbe(n,prefix)
 local canonical=B.from(O.ensureGateIndex(-n))
 assert(B.compare(canonical,cumulative)==0,"orak negatif ak sòm endepandan pa dakò "..n)
 assert(B.compare(old,B.sub(F,gaps[n]))==0,"legacy pa itilize dènye gap "..n)
 assert(type(ctx)=="table" and ctx.mode=="STAGE_36_DISCOVERY_18"
  and ctx.status=="LEGACY_NEGATIVE_GATE_COMPLETE"
  and ctx.commitToken==6 and #ctx.branchTrace==6
  and ctx.branchTrace[6]=="LEGACY_NEGATIVE_GATE_RESETS_FOUNDATION"
  and ctx.negativeGateIndex==-n
  and ctx.semanticState.missingPreviousGaps==true
  and ctx.semanticState.noCorrectCumulativeResultComputed==true
  and ctx.semanticState.historicalDivergence==(n>1)
  and ctx.semanticState.historicalNegativeGateDayDecimal==tostring(old)
  and ctx.metrics["legacy.negativeGate.calls"]==1
  and ctx.diagnostics[6].code=="DISCOVERY_18_FORGETS_PREVIOUS_NEGATIVE_GAPS",
  "six commits Discovery18 pa otantik: "..n)
 if B.compare(old,canonical)==0 then
  assert(n==1,"MATCH inatandi pou n="..n)
  matches=matches+1
 else
  assert(n>=2 and B.compare(old,canonical)>0,
   "EXPECTED_RED an pa gen siy pozitif: "..n)
  reds=reds+1
 end
 if n==2 then
  assert(B.compare(B.sub(old,canonical),gaps[1])==0,
   "diferans n=2 pa egzakteman gap(1)")
 end
end
assert(matches==1 and reds==31,
 "EXPECTED_RED kont pa 1 MATCH + 31 EXPECTED_RED")
local function rejected(n,s)
 local ok=pcall(S.legacyNegativeGateProbe,n,s)
 assert(not ok,"input envalid pa rejte")
end
rejected(0,{})
rejected(-1,{})
rejected(33,{})
rejected(2,{streams[1]})
rejected(1,{{first=1,directionStep=0}})
rejected(1,{{first="not-an-integer",directionStep=1}})
rejected(1,{streams[1],streams[2]})
local huge=B.from("170141183460469231731687303715884105728")
local hstreams={{first=huge,directionStep=1},{first=B.add(huge,999),directionStep=-1}}
local bigOld,bigCtx=S.legacyNegativeGateProbe(2,hstreams)
assert(B.compare(bigOld,F)<0 and bigCtx.semanticState.historicalDivergence==true,
 "BigInt gwo stream pa pase")
local repeatOld,repeatCtx=S.legacyNegativeGateProbe(2,hstreams)
assert(B.compare(bigOld,repeatOld)==0 and repeatCtx~=bigCtx
 and repeatCtx.semanticState~=bigCtx.semanticState,
 "retry oswa ownership pa izole")
local source=assert(io.open(root.."/src/legacy_negative_gate_position.lua","rb"))
local code=source:read("*a");source:close()
assert(not code:find("normative_oracle",1,true),
 "pwodiksyon pa gen dwa itilize orak test")
print("PASS Stage36 DISCOVERY18: 32 canonical negative gates, 1 MATCH + 31 EXPECTED_RED")
print("PASS Stage36 invalid inputs: 7 rejects; 2 BigInt replay calls; owned states detached")
