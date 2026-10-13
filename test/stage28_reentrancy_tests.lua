local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Patch=require("short_choice_patch")
local original=Patch.execute
local M=B.from("170141183460469231731687303715884105727")
local N=B.add(M,1)
for _,step in ipairs({-1,1}) do
 local busy=false
 local child,childCtx
 Patch.execute=function(...)
  if not busy then
   busy=true
   child,childCtx=S.legacyShortOnlyChoiceProbe(1,-step,B.pow(M,2))
   busy=false
  end
  return original(...)
 end
 local ok,outer,ctx=pcall(S.legacyShortOnlyChoiceProbe,M,step,N)
 Patch.execute=original
 assert(ok and child==nil and outer==nil and childCtx~=ctx
   and ctx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
   and childCtx.status=="LEGACY_WIDE_CHOICE_BLOCKED"
   and ctx.commitToken==1 and childCtx.commitToken==1)
 childCtx.semanticState.optionCountDecimal="TAMPERED"
 childCtx.diagnostics[1].options="TAMPERED"
 assert(ctx.semanticState.optionCountDecimal==tostring(N)
   and ctx.diagnostics[1].options==tostring(N))
end
assert(Patch.execute==original)
print("PASS Stage 28 reentrancy: 2 nested wide-block contexts, no ownership leak")
