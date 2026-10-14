local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_gate_gap")
local original=Old.execute
for _,signed in ipairs({-3,0,7}) do
 local active=false
 local nested,nestedCtx
 Old.execute=function(step,first,dir)
  if not active then
   active=true
   nested,nestedCtx=S.gateGapPatchProbe(-2,2,-1)
   active=false
  end
  return original(step,first,dir)
 end
 local ok,out,ctx=pcall(S.gateGapPatchProbe,signed,1,1)
 Old.execute=original
 assert(ok and B.compare(out,42)==0
  and nestedCtx~=ctx
  and ctx.commitToken==5 and nestedCtx.commitToken==5
  and ctx.semanticState~=nestedCtx.semanticState
  and ctx.legacyGapSemanticState~=nestedCtx.legacyGapSemanticState
  and ctx.choiceSemanticState~=nestedCtx.choiceSemanticState
  and ctx.diagnostics~=nestedCtx.diagnostics)
 nestedCtx.semanticState.correctedGapDecimal="TAMPERED"
 nestedCtx.legacyGapSemanticState.historicalGapDecimal="TAMPERED"
 assert(ctx.semanticState.correctedGapDecimal=="42"
  and ctx.legacyGapSemanticState.historicalGapDecimal=="43")
end
assert(Old.execute==original)
print("PASS Stage 33 nested: 3 independent five-commit gap repairs, no aliases")
