local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local S=require("spaghetti")
local Legacy=require("legacy_biased_choice")
local Patch=require("short_choice_patch")
local savedLegacy=Legacy.execute
local savedChoose=Patch.chooseShort
local M=B.from("170141183460469231731687303715884105727")
local failures,recovered=0,0
local function clean()
 local value,ctx=S.shortChoicePatchProbe(M,-1,5)
 assert(B.compare(value,5)==0
   and ctx.commitToken==3 and ctx.status=="PATCH_SHORT_CHOICE_COMPLETE"
   and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 recovered=recovered+1
end
local token={fault="LEGACY_PANIC"}
Legacy.execute=function(...) error(token,0) end
local ok,err=pcall(S.shortChoicePatchProbe,M,-1,5)
Legacy.execute=savedLegacy
assert(not ok and err==token)
failures=failures+1;clean()
for mode=1,7 do
 Legacy.execute=function(...)
  local value,ctx=savedLegacy(...)
  if mode==1 then ctx.commitToken=1
  elseif mode==2 then ctx.semanticState.optionCountDecimal="FAKE"
  elseif mode==3 then ctx.semanticState.resultRankDecimal="FAKE"
  elseif mode==4 then ctx.semanticState.didApplyAcceptanceThreshold=true
  elseif mode==5 then ctx.semanticState.ignoredFurtherAnswers=false
  elseif mode==6 then ctx.diagnostics[2].code="FORGED"
  else ctx.semanticState.nextDecimal="BAD" end
  return value,ctx
 end
 local passed=pcall(S.shortChoicePatchProbe,M,-1,5)
 Legacy.execute=savedLegacy
 assert(not passed,"PATCH 13 te aksepte falsifikasyon "..mode)
 failures=failures+1;clean()
end
for mode=1,4 do
 Patch.chooseShort=function(...)
   if mode==1 then error({fault="CHOOSE"},0) end
   if mode==2 then return B.from(0),{} end
   if mode==3 then return B.from(6),{} end
   return nil,{}
 end
 local passed=pcall(S.shortChoicePatchProbe,M,-1,5)
 Patch.chooseShort=savedChoose
 assert(not passed,"PATCH 13 te aksepte move rezilta "..mode)
 failures=failures+1;clean()
end
assert(failures==12 and recovered==12)
assert(Patch.chooseShort==savedChoose and Legacy.execute==savedLegacy)
print("PASS Stage 27 fault: 12 injected failures and 12 clean recoveries")
