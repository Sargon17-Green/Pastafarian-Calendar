local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local streams,expected={},B.from(F)
for i=1,3 do
 local sauce=O.sauce(F,F+i)
 streams[i]=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 local rank=O.chooseRankShort(streams[i],922)
 expected=B.add(expected,B.add(41,rank))
end
local result,ctx=S.positiveGatePatchProbe(3,streams)
local historical=S.legacyPositiveGateProbe(3,streams)
O.resetGateCache()
local oracle=O.ensureGateIndex(3)
assert(B.compare(result,expected)==0
 and B.compare(result,oracle)==0
 and B.compare(result,historical)>0
 and ctx.semanticState.correctedGateDayDecimal==tostring(oracle)
 and ctx.semanticState.gateIndex==3
 and ctx.legacyPositiveSemanticState.correctedPositiveChainAvailable==false)
print("PASS Stage 35 real: three authentic canonical sauce ranks and G(3) match normative oracle")
