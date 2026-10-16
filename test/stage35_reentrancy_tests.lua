local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_positive_gate_position")
local original=Legacy.execute
local outer={{first=1,directionStep=1},{first=2,directionStep=-1},{first=3,directionStep=1}}
local inner={{first=7,directionStep=-1},{first=8,directionStep=1}}
for n=2,3 do
 local busy=false
 local child,childCtx
 Legacy.execute=function(k,s)
  if not busy then
   busy=true
   child,childCtx=S.positiveGatePatchProbe(2,inner)
   busy=false
  end
  return original(k,s)
 end
 local requested={}
 for i=1,n do requested[i]=outer[i] end
 local ok,result,ctx=pcall(S.positiveGatePatchProbe,n,requested)
 Legacy.execute=original
 assert(ok,"Stage 35 nested child/parent failure: "..tostring(result))
 assert(ctx~=childCtx and ctx.commitToken==7 and childCtx.commitToken==7
  and ctx.semanticState~=childCtx.semanticState
  and ctx.legacyPositiveSemanticState~=childCtx.legacyPositiveSemanticState
  and ctx.gapSourceStates~=childCtx.gapSourceStates
  and ctx.positiveGapDecimals~=childCtx.positiveGapDecimals
  and ctx.diagnostics~=childCtx.diagnostics)
 childCtx.semanticState.correctedGateDayDecimal="TAMPERED"
 childCtx.gapSourceStates[1].correctedGapDecimal="TAMPERED"
 childCtx.legacyPositiveSemanticState.lastGapDecimal="TAMPERED"
 assert(ctx.semanticState.correctedGateDayDecimal~="TAMPERED"
  and ctx.gapSourceStates[1].correctedGapDecimal~="TAMPERED"
  and ctx.legacyPositiveSemanticState.lastGapDecimal~="TAMPERED")
end
assert(Legacy.execute==original)
print("PASS Stage 35 reentrancy: 2 nested corrected positive chains and no owned-state aliases")
