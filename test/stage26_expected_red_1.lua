local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local O=require("normative_oracle")
local B=require("bigint")
local S=require("spaghetti")
local seed=B.from(O.M)
local step=1
local n=B.from(5)
local legacy,ctx=S.legacyBiasedChoiceProbe(seed,step,n)
local wanted=O.chooseRankShort({first=seed,directionStep=step},n)
assert(B.compare(legacy,B.from(2))==0
 and B.compare(wanted,B.from(1))==0
 and B.compare(legacy,wanted)~=0
 and ctx.semanticState.consumedAnswerCount==1
 and ctx.semanticState.didApplyAcceptanceThreshold==false,
 "Kontra EXPECTED_RED 1 pa konplè")
error("EXPECTED_RED Stage 26 DISCOVERY 13 witness 1: modulo san rejè",0)
