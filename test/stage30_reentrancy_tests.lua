local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_gate_question_adapter")
local original=Old.oldGateQuestionDay
for _,step in ipairs({-1,-10,2}) do
 local busy=false
 local nested,child
 Old.oldGateQuestionDay=function(n)
  if not busy then
   busy=true
   nested,child=S.legacyGateQuestionProbe(-3)
   busy=false
  end
  return original(n)
 end
 local ok,outer,ctx=pcall(S.legacyGateQuestionProbe,step)
 Old.oldGateQuestionDay=original
 assert(ok and B.compare(nested,-15055668)==0
  and ctx~=child and ctx.commitToken==2 and child.commitToken==2
  and ctx.semanticState~=child.semanticState and ctx.diagnostics~=child.diagnostics)
 child.semanticState.signedStepDecimal="TAMPERED"
 child.diagnostics[1].signedStep="TAMPERED"
 assert(ctx.semanticState.signedStepDecimal==tostring(B.from(step))
  and ctx.diagnostics[1].signedStep==tostring(B.from(step)))
end
assert(Old.oldGateQuestionDay==original)
print("PASS Stage 30 nested: 3 reentrant calls without owned-state leakage")
