-- DISCOVERY 17: 96 sekans detèminis verifye pèt soum ak lòd pòtay yo.
local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local cases,wrongCases=0,0
for n=1,24 do
 for scenario=1,4 do
  local streams={}
  local canonical=B.from(F)
  local lastGap
  for i=1,n do
   local first=1+((i*177+scenario*269)%920)
   local dir=(i+scenario)%2==0 and 1 or -1
   streams[i]={first=B.from(first),directionStep=dir}
   local rank=O.chooseRankShort(streams[i],922)
   lastGap=B.add(41,rank)
   canonical=B.add(canonical,lastGap)
  end
  local historical,ctx=S.legacyPositiveGateProbe(n,streams)
  assert(B.compare(historical,B.add(F,lastGap))==0)
  assert(ctx.semanticState.gateIndex==n and ctx.gateIndex==n
     and ctx.correctCumulativeDayForAudit==nil
     and ctx.semanticState.noCorrectCumulativeResultComputed==true
     and ctx.commitToken==6 and #ctx.positiveGapDecimals==n)
  if n==1 then assert(B.compare(historical,canonical)==0)
  else
   assert(B.compare(historical,canonical)<0)
   wrongCases=wrongCases+1
  end
  cases=cases+1
 end
end
assert(cases==96 and wrongCases==92)
-- Lè dezyèm espas la rete 42, premye espas 963 ka fè jou legacy retounen dèyè.
local backward={{first=922,directionStep=1},{first=1,directionStep=1}}
local gate1=S.legacyPositiveGateProbe(1,{backward[1]})
local gate2=S.legacyPositiveGateProbe(2,backward)
local firstRank=O.chooseRankShort(backward[1],922)
local lastRank=O.chooseRankShort(backward[2],922)
assert(B.compare(gate1,B.add(F,B.add(41,firstRank)))==0
 and B.compare(gate2,B.add(F,B.add(41,lastRank)))==0
 and B.compare(gate2,gate1)<0)
local correctGate2=B.add(gate1,B.add(41,lastRank))
assert(B.compare(correctGate2,gate1)>0)
-- De diferan istwa pou premye gap la bay menm G_legacy(2);
-- oracle kumilatif la chanje, paske premye gap la konte.
local one={{first=1,directionStep=1},{first=17,directionStep=-1}}
local another={{first=500,directionStep=1},{first=17,directionStep=-1}}
local oldA,ctxA=S.legacyPositiveGateProbe(2,one)
local oldB,ctxB=S.legacyPositiveGateProbe(2,another)
assert(B.compare(oldA,oldB)==0
 and ctxA.semanticState.gapDecimals[1]~=ctxB.semanticState.gapDecimals[1]
 and ctxA.semanticState.gapDecimals[2]==ctxB.semanticState.gapDecimals[2])
local rankA=O.chooseRankShort(one[1],922)
local rankB=O.chooseRankShort(another[1],922)
local last=O.chooseRankShort(one[2],922)
assert(B.compare(rankA,rankB)~=0
 and B.compare(B.add(F,B.add(B.add(41,rankA),B.add(41,last))),
               B.add(F,B.add(B.add(41,rankB),B.add(41,last))))~=0)
print("PASS Stage 34 properties: 96 deterministic chains, 92 cumulative differences, backwards gate, prefix independence")
