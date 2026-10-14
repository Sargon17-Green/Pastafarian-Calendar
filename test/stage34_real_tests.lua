local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local streams,expectedGaps={},{}
for i=1,3 do
 local sauce=O.sauce(F,F+i)
 streams[i]=O.askBowl(sauce,1,O.SEAL_GATE_GAP)
 local rank=O.chooseRankShort(streams[i],922)
 expectedGaps[i]=B.add(41,rank)
end
local wanted=B.add(F,B.add(expectedGaps[1],B.add(expectedGaps[2],expectedGaps[3])))
local legacy,ctx=S.legacyPositiveGateProbe(3,streams)
assert(B.compare(legacy,B.add(F,expectedGaps[3]))==0
 and B.compare(legacy,wanted)~=0
 and ctx.correctCumulativeDayForAudit==nil
 and ctx.gapSourceStates[1].questionDayDecimal==tostring(B.add(F,1))
 and ctx.gapSourceStates[2].questionDayDecimal==tostring(B.add(F,2))
 and ctx.gapSourceStates[3].questionDayDecimal==tostring(B.add(F,3)))
O.resetGateCache()
local oracleGate=O.ensureGateIndex(3)
assert(B.compare(oracleGate,wanted)==0)
print("PASS Stage 34 real: 3 genuine canonical sauce-derived gaps; G(3) needs cumulative sum")
