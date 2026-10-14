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
 local outerStreams={}
 for i=1,n do outerStreams[i]=streams[i] end
 local ok,outer,ctx=pcall(S.legacyPositiveGateProbe,n,outerStreams)
 Gap.execute=original
 assert(ok,"Stage 34 nested n="..n.." outer call threw: "..tostring(outer))
 assert(type(ctx)=="table" and type(child)=="table",
  "Stage 34 nested n="..n.." missing outer/inner context")
 assert(ctx~=child,"Stage 34 nested n="..n.." context alias")
 assert(ctx.commitToken==6 and child.commitToken==6,
  "Stage 34 nested n="..n.." commit counts "..tostring(ctx.commitToken).."/"..tostring(child.commitToken))
 assert(ctx.semanticState~=child.semanticState,
  "Stage 34 nested n="..n.." semanticState alias")
 assert(ctx.gapSourceStates~=child.gapSourceStates,
  "Stage 34 nested n="..n.." gapSourceStates alias")
 assert(ctx.positiveGapDecimals~=child.positiveGapDecimals,
  "Stage 34 nested n="..n.." positiveGapDecimals alias")
 assert(ctx.diagnostics~=child.diagnostics,
  "Stage 34 nested n="..n.." diagnostics alias")
 child.semanticState.lastGapDecimal="TAMPERED"
 child.gapSourceStates[1].correctedGapDecimal="TAMPERED"
 assert(ctx.semanticState.lastGapDecimal~="TAMPERED"
  and ctx.gapSourceStates[1].correctedGapDecimal~="TAMPERED")
end
assert(Gap.execute==original)
print("PASS Stage 34 reentrancy: 2 nested positive gate chains, all state detached")
