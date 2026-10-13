local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local f=O.FOUNDATION_DAY
local sauce=O.sauce(f,f)
local stream=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
local n=B.add(O.M,1)
local oracle=O.chooseRankWide(stream,n)
local blocked,ctx=S.legacyShortOnlyChoiceProbe(stream.first,stream.directionStep,n)
assert(B.compare(oracle,1)>=0 and B.compare(oracle,n)<=0
 and blocked==nil and ctx.commitToken==1
 and ctx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
 and ctx.semanticState.firstDecimal==tostring(stream.first))
print("PASS Stage 28 real: canonical sauce stream has valid wide answer, legacy short-only blocks")
