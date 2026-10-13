local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
for _,n in ipairs({1,2}) do
 local corrected,ctx=S.gateQuestionPatchProbe(-n)
 local legacy=S.legacyGateQuestionProbe(-n)
 assert(B.compare(corrected,F-n)==0
  and B.compare(legacy,F+n)==0
  and ctx.legacyGateSemanticState.queriedDayDecimal==tostring(B.add(F,n)))
 local sauceRight=O.sauce(F,F-n)
 local sauceWrong=O.sauce(F,F+n)
 local different=false
 for k=1,6 do
  if B.compare(sauceRight.bowls[k],sauceWrong.bowls[k])~=0 then different=true end
 end
 assert(different,"PATCH 15: real sauce sources no longer distinguish sides")
end
print("PASS Stage 31 real: two repaired authentic Foundation-side sauce pairs, legacy wrong side preserved")
