local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local n=4
local streams={}
for i=1,n do streams[i]={first=1,directionStep=1} end
local historical,ctx=S.legacyPositiveGateProbe(n,streams)
local trueDay=B.add(O.FOUNDATION_DAY,B.mulSmall(B.from(42),n))
assert(B.compare(historical,B.add(O.FOUNDATION_DAY,42))==0
 and B.compare(historical,trueDay)~=0
 and ctx.semanticState.historicalDivergence
 and ctx.commitToken==6)
error("EXPECTED_RED Stage 34 DISCOVERY 17 witness 3: positive gate forgot prior gaps",0)
