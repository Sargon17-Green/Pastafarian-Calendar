local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_gate_question_adapter")
local original=Old.execute
for _,step in ipairs({-1,0,19}) do
 local busy=false
 local inner,innerCtx
 Old.execute=function(signed)
  if not busy then
   busy=true
   inner,innerCtx=S.gateQuestionPatchProbe(-3)
   busy=false
  end
  return original(signed)
 end
 local ok,outer,ctx=pcall(S.gateQuestionPatchProbe,step)
 Old.execute=original
 assert(ok and B.compare(inner,-15055674)==0
   and B.compare(outer,B.add(-15055671,step))==0
   and ctx~=innerCtx and ctx.commitToken==3 and innerCtx.commitToken==3
   and ctx.semanticState~=innerCtx.semanticState
   and ctx.legacyGateSemanticState~=innerCtx.legacyGateSemanticState
   and ctx.diagnostics~=innerCtx.diagnostics)
 innerCtx.semanticState.signedStepDecimal="TAMPERED"
 innerCtx.legacyGateSemanticState.queriedDayDecimal="TAMPERED"
 assert(ctx.semanticState.signedStepDecimal==tostring(B.from(step))
  and ctx.legacyGateSemanticState.queriedDayDecimal==tostring(B.add(-15055671,B.abs(step))))
end
assert(Old.execute==original)
print("PASS Stage 31 nested: 3 true nested PATCH 15 calls, no historical/current state alias")
