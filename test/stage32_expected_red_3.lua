local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local step,first,dir=7,7,1
local rank=O.chooseRankShort({first=B.from(first),directionStep=dir},922)
local got,ctx=S.legacyGateGapProbe(step,first,dir)
assert(B.compare(got,B.add(42,rank))==0
 and B.compare(got,B.add(41,rank))~=0
 and ctx.semanticState.legacyOffByOnePreserved)
error("EXPECTED_RED Stage 32 DISCOVERY 16 witness 3: gate gap legacy offset plus one",0)
