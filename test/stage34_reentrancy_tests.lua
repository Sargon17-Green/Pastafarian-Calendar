local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Gap=require("gate_gap_patch")
local original=Gap.execute
local streams={{first=1,directionStep=1},{first=2,directionStep=-1},{first=3,directionStep=1}}
local nestedStreams={{first=7,directionStep=-1},{first=8,directionStep=1}}
for n=2,3 do
 local busy=false
 local childValue,child
 Gap.execute=function(step,first,dir)
  if not busy then
   busy=true
   childValue,child=S.legacyPositiveGateProbe(2,nestedStreams)
   busy=false
  end
  return original(step,first,dir)
 end
 local ok,outer,ctx=pcall(S.legacyPositiveGateProbe,n,streams)
 Gap.execute=original
 assert(ok and ctx~=child
  and ctx.commitToken==6 and child.commitToken==6
  and ctx.semanticState~=child.semanticState
  and ctx.gapSourceStates~=child.gapSourceStates
  and ctx.positiveGapDecimals~=child.positiveGapDecimals
  and ctx.diagnostics~=child.diagnostics)
 child.semanticState.lastGapDecimal="TAMPERED"
 child.gapSourceStates[1].correctedGapDecimal="TAMPERED"
 assert(ctx.semanticState.lastGapDecimal~="TAMPERED"
  and ctx.gapSourceStates[1].correctedGapDecimal~="TAMPERED")
end
assert(Gap.execute==original)
print("PASS Stage 34 reentrancy: 2 nested positive gate chains, all state detached")
