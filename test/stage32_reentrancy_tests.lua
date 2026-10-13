local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Short=require("short_choice_patch")
local original=Short.execute
for _,signed in ipairs({-5,0,17}) do
 local busy=false
 local childValue,child
 Short.execute=function(first,dir,n)
  if not busy then
   busy=true
   childValue,child=S.legacyGateGapProbe(-3,2,-1)
   busy=false
  end
  return original(first,dir,n)
 end
 local ok,result,ctx=pcall(S.legacyGateGapProbe,signed,1,1)
 Short.execute=original
 assert(ok and B.compare(result,43)==0 and child~=ctx
  and child.commitToken==4 and ctx.commitToken==4
  and ctx.semanticState~=child.semanticState
  and ctx.choiceSemanticState~=child.choiceSemanticState)
 child.semanticState.questionDayDecimal="TAMPERED"
 child.choiceSemanticState.firstDecimal="TAMPERED"
 assert(ctx.semanticState.questionDayDecimal==tostring(B.add(-15055671,signed))
  and ctx.choiceSemanticState.firstDecimal=="1")
end
assert(Short.execute==original)
print("PASS Stage 32 nested: 3 independent gate-gap contexts, no aliases")
