local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Old=require("legacy_short_only_choice")
local M=B.from("170141183460469231731687303715884105727")
local N=B.add(M,1)
local original=Old.execute
for _,direction in ipairs({-1,1}) do
 local active=false
 local nested,inner
 Old.execute=function(...)
  if not active then
   active=true
   nested,inner=S.wideChoicePatchProbe(1,-direction,B.mul(M,M))
   active=false
  end
  return original(...)
 end
 local ok,outer,ctx=pcall(S.wideChoicePatchProbe,2,direction,N)
 Old.execute=original
 assert(ok and outer and nested
    and ctx~=inner and ctx.commitToken==2 and inner.commitToken==2
    and ctx.semanticState~=inner.semanticState
    and ctx.legacyWideSemanticState~=inner.legacyWideSemanticState
    and ctx.status=="PATCH_WIDE_CHOICE_COMPLETE"
    and inner.status=="PATCH_WIDE_CHOICE_COMPLETE")
 inner.semanticState.digitRepliesDecimal[1]="TAMPERED"
 inner.legacyWideSemanticState.optionCountDecimal="TAMPERED"
 assert(ctx.semanticState.digitRepliesDecimal[1]~="TAMPERED"
    and ctx.legacyWideSemanticState.optionCountDecimal==tostring(N))
end
assert(Old.execute==original)
print("PASS Stage 29 reentrancy: 2 nested repaired wide streams, no state alias")
