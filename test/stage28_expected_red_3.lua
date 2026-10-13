local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local n=B.mul(O.M,O.M)
local first=B.from(3)
local step=1
local blocked,ctx=S.legacyShortOnlyChoiceProbe(first,step,n)
local wanted=O.chooseRankWide({first=first,directionStep=step},n)
assert(blocked==nil and ctx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
  and ctx.semanticState.wideRankAvailable==false
  and B.compare(wanted,1)>=0 and B.compare(wanted,n)<=0,
 "Invalid EXPECTED_RED witness 3")
error("EXPECTED_RED Stage 28 DISCOVERY 14 witness 3: N>M blocked by short-only legacy",0)
