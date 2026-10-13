local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local actual,ctx=S.legacyGateQuestionProbe(-1)
local bad=B.add(O.FOUNDATION_DAY,1)
local norm=B.sub(O.FOUNDATION_DAY,1)
assert(B.compare(actual,bad)==0 and B.compare(actual,norm)~=0
 and ctx.semanticState.signLostForNegative)
error("EXPECTED_RED Stage 30 DISCOVERY 15 witness 1: negative gate sign lost",0)
