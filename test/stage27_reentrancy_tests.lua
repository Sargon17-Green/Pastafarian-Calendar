local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_biased_choice")
local saved=Legacy.execute
local M=B.from("170141183460469231731687303715884105727")
for _,direction in ipairs({-1,1}) do
 local inside=false
 local inner,child
 Legacy.execute=function(...)
  if not inside then
   inside=true
   inner,child=S.shortChoicePatchProbe(M,-direction,5)
   inside=false
  end
  return saved(...)
 end
 local ok,result,parent=pcall(S.shortChoicePatchProbe,M,direction,5)
 Legacy.execute=saved
 assert(ok and child and parent and child~=parent
   and child.commitToken==3 and parent.commitToken==3)
 assert(B.compare(result,direction==1 and 1 or 5)==0)
 assert(B.compare(inner,direction==1 and 5 or 1)==0)
 child.semanticState.acceptedAnswerDecimal="ALTERED"
 child.legacyChoiceSemanticState.resultRankDecimal="ALTERED"
 assert(parent.semanticState.acceptedAnswerDecimal~="ALTERED"
  and parent.legacyChoiceSemanticState.resultRankDecimal~="ALTERED")
end
assert(Legacy.execute==saved)
print("PASS Stage 27 nested: two independent patched rejection invocations")
