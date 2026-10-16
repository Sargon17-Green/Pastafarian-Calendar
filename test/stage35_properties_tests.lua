local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=B.from(O.FOUNDATION_DAY)
local cases,differences=0,0
for n=1,24 do
 for scenario=1,4 do
  local streams={}
  local canonical=B.from(F)
  for i=1,n do
   local first=1+((i*177+scenario*269)%920)
   local direction=(i+scenario)%2==0 and 1 or -1
   streams[i]={first=B.from(first),directionStep=direction}
   local rank=O.chooseRankShort(streams[i],922)
   canonical=B.add(canonical,B.add(41,rank))
  end
  local patched,ctx=S.positiveGatePatchProbe(n,streams)
  assert(B.compare(patched,canonical)==0
   and ctx.semanticState.gateIndex==n
   and ctx.semanticState.correctedGateDayDecimal==tostring(canonical))
  local wrong=S.legacyPositiveGateProbe(n,streams)
  if n==1 then assert(B.compare(patched,wrong)==0)
  else
   assert(B.compare(patched,wrong)>0)
   differences=differences+1
  end
  cases=cases+1
 end
end
assert(cases==96 and differences==92)
local backward={{first=922,directionStep=1},{first=1,directionStep=1}}
local g1=S.positiveGateDaySpaghetti(1,{backward[1]})
local g2=S.positiveGateDaySpaghetti(2,backward)
assert(B.compare(g2,g1)>0)
local old1=S.legacyPositiveGateProbe(1,{backward[1]})
local old2=S.legacyPositiveGateProbe(2,backward)
assert(B.compare(old2,old1)<0)
local a={{first=1,directionStep=1},{first=17,directionStep=-1}}
local b={{first=500,directionStep=1},{first=17,directionStep=-1}}
local oldA=S.legacyPositiveGateProbe(2,a)
local oldB=S.legacyPositiveGateProbe(2,b)
local newA=S.positiveGatePatchProbe(2,a)
local newB=S.positiveGatePatchProbe(2,b)
assert(B.compare(oldA,oldB)==0
 and B.compare(newA,newB)~=0)
print("PASS Stage 35 properties: 96 exact chains, strict gate order, prefix sensitivity restored")
