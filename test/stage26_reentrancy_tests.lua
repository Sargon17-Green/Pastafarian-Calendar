local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_biased_choice")
local previous=Legacy.answerAt
local M=B.from("170141183460469231731687303715884105727")
local count=0
for _,step in ipairs({1,-1}) do
 local busy=false
 local child,childCtx
 Legacy.answerAt=function(...)
  if not busy then
   busy=true
   child,childCtx=S.legacyBiasedChoiceProbe(M,-step,5)
   busy=false
  end
  return previous(...)
 end
 local ok,parent,parentCtx=pcall(S.legacyBiasedChoiceProbe,M,step,5)
 Legacy.answerAt=previous
 assert(ok and parent and parentCtx and child and childCtx
    and parentCtx~=childCtx
    and parentCtx.commitToken==2 and childCtx.commitToken==2)
 childCtx.semanticState.resultRankDecimal="TAMPERED"
 childCtx.diagnostics[2].rank="TAMPERED"
 assert(parentCtx.semanticState.resultRankDecimal~="TAMPERED"
    and parentCtx.diagnostics[2].rank~="TAMPERED")
 count=count+1
end
assert(count==2 and Legacy.answerAt==previous)
print("PASS Stage 26 reentrance: two real nested SAVE streams, owned context")
