local root=arg[1] or "."
package.path=root.."/src/?.lua;"..package.path
local Base=require("monster_base")
local S=require("spaghetti")
local a=S.bootstrapProbe(-15055671,-15055671)
local b=S.bootstrapProbe(-15055671,-15055670)
assert(a~=b)
assert(a.semanticState~=b.semanticState)
assert(a.metrics~=b.metrics)
assert(a.status=="VALIDATED" and b.status=="VALIDATED")
assert(a.pendingSemanticState==nil and b.pendingSemanticState==nil)
local ctx=Base.MonsterContext.new(1,2)
ctx:beginSemanticUpdate({x=3})
assert(ctx.pendingSemanticState.x==3 and ctx.semanticState.x==nil)
ctx:commitSemanticUpdate()
assert(ctx.semanticState.x==3 and ctx.commitToken==1)
ctx:beginSemanticUpdate({x=4})
ctx:rollbackSemanticUpdate()
assert(ctx.semanticState.x==3 and ctx.pendingSemanticState==nil)
local candidate={nested={value=9}}
ctx:beginSemanticUpdate(candidate)
candidate.nested.value=111
assert(ctx.pendingSemanticState.nested.value==9)
local oldPending=ctx.pendingSemanticState
ctx:commitSemanticUpdate()
oldPending.nested.value=222
assert(ctx.semanticState.nested.value==9)
ctx:beginSemanticUpdate({nested={value=10}})
ctx.semanticState.nested.value=333
ctx:rollbackSemanticUpdate()
assert(ctx.semanticState.nested.value==9)
assert(not pcall(function() ctx:beginSemanticUpdate(nil) end))
assert(ctx.pendingSemanticState==nil)
local ok=pcall(S.calendarDateSpaghetti)
assert(not ok)
print("PASS baz production")
