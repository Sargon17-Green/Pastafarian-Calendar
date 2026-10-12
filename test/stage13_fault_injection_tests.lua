local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local P=require("prior_patch")
local Old=require("legacy_prior")
local Hidden=require("hidden_patch")
local F=-15055671
local visible={B.from(23),B.from(71),B.from("1"..string.rep("0",93))}
local first=S.priorSpaghetti(visible,F,F,1,1)
local originalExecute=Old.execute
local originalRead=Old.legacyPrior
local originalHiddenRead=Hidden.hiddenByNearness
local faults,recoveries=0,0
local function recovery()
 local value,ctx=S.priorPatchProbe(visible,F,F,1,1)
 assert(B.compare(value,first)==0)
 assert(ctx.commitToken==2 and ctx.status=="PATCH_PRIOR_RETURNED")
 assert(ctx.nestedHiddenContext.commitToken==2)
 assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_PRIOR" and ctx.branchTrace[2]=="PRIOR_PATCH")
 recoveries=recoveries+1
end
for k=1,7 do
 local marker="INJECTED_PATCH_HIDDEN_"..k
 Hidden.hiddenByNearness=function()error(marker,0)end
 local ok,err=pcall(P.execute,visible,F,F,1,k)
 Hidden.hiddenByNearness=originalHiddenRead
 assert(not ok and tostring(err):find(marker,1,true),"Hidden failure not propagated")
 faults=faults+1
 recovery()
end
for k=1,7 do
 local marker="INJECTED_PRIOR_LEGACY_"..k
 Old.execute=function()error(marker,0)end
 local ok,err=pcall(P.execute,visible,F,F,1,k)
 Old.execute=originalExecute
 assert(not ok and tostring(err):find(marker,1,true),"Legacy failure not propagated")
 faults=faults+1
 recovery()
end
-- wout vizib la dwe kontinye depann de vrè fonksyon legacy a.
Old.legacyPrior=function()error("INJECTED_VISIBLE_READ",0)end
local ok,err=pcall(P.execute,visible,F,F,3,1)
Old.legacyPrior=originalRead
assert(not ok and tostring(err):find("INJECTED_VISIBLE_READ",1,true))
faults=faults+1
recovery()
-- Yon map fizik ki pèdi slot li a pa dwe tounen yon rezilta tès fo.
local physical={};for k=1,7 do physical[k]=B.from(100+k) end
for k=1,7 do
 local partial={};for j=1,7 do if j~=k then partial[j]=B.from(physical[j]) end end
 local slot=8-k
 assert(not pcall(P.priorPatch,visible,partial,1,slot))
 faults=faults+1
end
-- Tout done ak errè ki sòti nan yon apèl pa dwe kontamine pwochen an.
local value,ctx=S.priorPatchProbe(visible,F,F,1,1)
ctx.semanticState.resultDecimal="CORRUPT"
ctx.branchTrace[1]="CORRUPT"
ctx.diagnostics[1].code="CORRUPT"
ctx.metrics["prior.patch.calls"]=999
ctx.nestedHiddenContext.semanticState.physical7="CORRUPT"
local newValue,newCtx=S.priorPatchProbe(visible,F,F,1,1)
assert(B.compare(value,newValue)==0)
assert(newCtx.semanticState.resultDecimal==tostring(newValue))
assert(newCtx.branchTrace[1]=="LEGACY_PRIOR")
assert(newCtx.diagnostics[1].code=="HIDDEN_HISTORY_NOT_RESOLVED")
assert(newCtx.metrics["prior.patch.calls"]==1)
assert(newCtx.nestedHiddenContext.semanticState.physical7~="CORRUPT")
assert(Old.execute==originalExecute and Old.legacyPrior==originalRead)
assert(Hidden.hiddenByNearness==originalHiddenRead)
assert(faults==22 and recoveries==15)
print("PASS rezilyans PATCH 06: "..faults.." erè izole, "..recoveries.." rekiperasyon, eta pwòp")
