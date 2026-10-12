local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local visual={B.from("170141183460469231731687303715884105728"),
 B.from("-"..string.rep("9",110)),B.from("1"..string.rep("0",140)),
 B.from(4),B.from(5),B.from(6),B.from(7),B.from(8)}
local seed=117
local cases={{F,F},{F-1,F+1},{F+3,F-2},{F-20,F-15},{F+17,F+29},
 {F-125,F-125},{F+125,F+125},{F-73,F+137},{F+137,F-73},
 {F-1000,F-999},{F+999,F+1000},{F-2048,F+2048}}
for n=1,12 do
 seed=(seed*48271)%2147483647
 local c=F+(seed%20001)-10000
 seed=(seed*48271)%2147483647
 local t=F+(seed%20001)-10000
 cases[#cases+1]={c,t}
end
local original={};for k=1,8 do original[k]=tostring(visual[k]) end
local hiddenChecks,visibleChecks=0,0
for _,pair in ipairs(cases) do
 local c,t=pair[1],pair[2]
 local hidden=O.buildHiddenDrops(O.workCounts(c,t),O.STONES)
 for i=1,8 do for back=1,7 do
  local slot=i-back
  local corrected,ctx=S.priorPatchProbe(visual,c,t,i,back)
  local public=S.priorSpaghetti(visual,c,t,i,back)
  local expected=slot>=1 and visual[slot] or hidden[1-slot]
  assert(B.compare(corrected,expected)==0 and B.compare(public,expected)==0)
  assert(ctx.mode=="STAGE_13_PATCH_06" and ctx.status=="PATCH_PRIOR_RETURNED")
  assert(ctx.commitToken==2 and ctx.currentHandler=="PRIOR_PATCH" and
         ctx.previousHandler=="LEGACY_PRIOR")
  assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_PRIOR" and
         ctx.branchTrace[2]=="PRIOR_PATCH")
  assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
  assert(ctx.nestedHiddenContext.commitToken==2)
  assert(ctx.metrics["legacy.prior.calls"]==1 and ctx.metrics["prior.patch.calls"]==1)
  assert(ctx.semanticState.requestedSlot==slot and ctx.semanticState.legacyCallPreserved)
  assert(ctx.semanticState.hiddenStorageUnchanged and ctx.semanticState.hasValue)
  assert(ctx.semanticState.resultDecimal==tostring(expected))
  assert(#ctx.diagnostics==2)
  if slot<=0 then
   local k=1-slot
   assert(ctx.semanticState.source=="HIDDEN_HISTORY_BACKFILL")
   assert(ctx.semanticState.hiddenIndex==k and ctx.semanticState.physicalHiddenIndex==8-k)
   assert(ctx.semanticState.originalLegacyMissing and ctx.semanticState.legacyValueDecimal=="MISSING")
   assert(ctx.metrics["legacy.prior.misses"]==1 and ctx.metrics["prior.patch.hiddenReads"]==1)
   assert(ctx.diagnostics[1].code=="HIDDEN_HISTORY_NOT_RESOLVED" and
          ctx.diagnostics[2].code=="PATCH_06_REMAP_TO_HIDDEN")
   hiddenChecks=hiddenChecks+1
  else
   assert(ctx.semanticState.source=="VISIBLE_HISTORY_PRESERVED")
   assert(ctx.semanticState.hiddenIndex=="NONE" and not ctx.semanticState.originalLegacyMissing)
   assert(ctx.metrics["prior.patch.visibleReads"]==1 and ctx.metrics["prior.patch.hiddenReads"]==nil)
   assert(ctx.diagnostics[2].code=="PATCH_06_PRESERVE_VISIBLE_LEGACY")
   visibleChecks=visibleChecks+1
  end
 end end
end
assert(#cases==24 and hiddenChecks==672 and visibleChecks==672)
for k=1,8 do assert(tostring(visual[k])==original[k],"Antre chanje") end
print("PASS PATCH 06: 1344 lekti sou 24 pè, 672 hidden, 672 vizib, de komit ak legacy prezève")
