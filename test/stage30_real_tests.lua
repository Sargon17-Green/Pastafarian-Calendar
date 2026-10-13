local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
for _,n in ipairs({1,2,10}) do
 local wrong,ctx=S.legacyGateQuestionProbe(-n)
 assert(B.compare(wrong,F+n)==0 and B.compare(wrong,F-n)~=0
  and ctx.semanticState.signLostForNegative)
 local expectedSauce=O.sauce(F,F-n)
 local wrongSauce=O.sauce(F,F+n)
 local different=false
 for i=1,6 do
  if B.compare(expectedSauce.bowls[i],wrongSauce.bowls[i])~=0 then different=true end
 end
 assert(different,"Negative and positive day sauce indistinguishable")
end
print("PASS Stage 30 real: 3 signed gate queries lead to distinct canonical sauce inputs/outputs")
