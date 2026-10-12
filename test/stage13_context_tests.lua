local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local Patch=require("prior_patch")
local F=O.FOUNDATION_DAY
local visual={B.from("170141183460469231731687303715884105728"),
 B.from("-"..string.rep("9",110)),B.from("1"..string.rep("0",140)),
 B.from(4),B.from(5),B.from(6),B.from(7),B.from(8)}
-- Fonksyon direktè sou depo fizik ki gen sèt plas ranvèse.
local physical={}
for k=1,7 do physical[k]=B.from(80+k) end
for i=1,8 do for back=1,7 do
 local slot=i-back
 local result=Patch.priorPatch(visual,physical,i,back)
 local expected=slot>=1 and visual[slot] or physical[8-(1-slot)]
 assert(B.compare(result,expected)==0, "Fonksyon direktè pa respekte endis history")
end end

-- Menm si yon itilizatè mete valè fo nan slot 0 ak -6, PATCH 06 pa dwe
-- fè mòd legacy a pase devan sèt hidden yo ki deja kalkile.
local adversarial={};for k,v in pairs(visual) do adversarial[k]=B.from(v) end
adversarial[0]=B.from(998)
adversarial[-6]=B.from(997)
local oracleFoundation=O.buildHiddenDrops(O.workCounts(F,F),O.STONES)
for _,back in ipairs({1,7}) do
 local k=back
 local actual,ctx=S.priorPatchProbe(adversarial,F,F,1,back)
 assert(B.compare(actual,oracleFoundation[k])==0)
 assert(ctx.semanticState.originalLegacyMissing==false)
 assert(ctx.semanticState.legacyValueDecimal==tostring(adversarial[1-back]))
 assert(ctx.semanticState.source=="HIDDEN_HISTORY_BACKFILL")
 assert(tostring(adversarial[1-back])==(back==1 and "998" or "997"))
end

-- Kòd legacy a rete visib menm apre koreksyon an.
local old,oldCtx=S["legacy".."PriorProbe"](visual,F,F,1,1)
assert(old==nil and oldCtx.commitToken==1 and oldCtx.status=="LEGACY_PRIOR_MISSING")
local unexpected={}
for k=1,7 do
 local value=S["legacy".."PriorProbe"](visual,F,F,1,k)
 assert(value==nil)
 unexpected[#unexpected+1]=tostring(1-k)
end
assert(table.concat(unexpected,",")=="0,-1,-2,-3,-4,-5,-6")

-- Egzèsis ki pwouve pa gen alias/tranzaksyon lòt invocation.
local first,ctx=S.priorPatchProbe(visual,F,F,1,1)
ctx.semanticState.resultDecimal="corrupt"
ctx.metrics["prior.patch.calls"]=99
ctx.diagnostics[1].code="corrupt"
ctx.branchTrace[1]="corrupt"
ctx.nestedHiddenContext.semanticState.physical7="corrupt"
local second,fresh=S.priorPatchProbe(visual,F,F,1,1)
assert(B.compare(second,first)==0)
assert(fresh.semanticState.resultDecimal==tostring(second))
assert(fresh.metrics["prior.patch.calls"]==1)
assert(fresh.diagnostics[1].code=="HIDDEN_HISTORY_NOT_RESOLVED")
assert(fresh.branchTrace[1]=="LEGACY_PRIOR")
assert(fresh.nestedHiddenContext.semanticState.physical7~="corrupt")

-- De fòm eleman ki absan oubyen ki pa valab yo dwe trete net.
local omitted={ [1]=B.from(17) }
local missing,missingCtx=S.priorPatchProbe(omitted,F,F,3,1)
assert(missing==nil and missingCtx.status=="PATCH_PRIOR_MISSING")
assert(missingCtx.semanticState.originalLegacyMissing==true)
local invalids={0,-1,1.5,"1",true,{}}
for _,v in ipairs(invalids) do
 assert(not pcall(S.priorSpaghetti,visual,F,F,v,1))
 assert(not pcall(S.priorSpaghetti,visual,F,F,1,v))
end
for _,v in ipairs({0,8,1.5,"1"}) do
 assert(not pcall(Patch.priorPatch,visual,physical,1,v))
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS contexte PATCH 06: legacy, depo fwode, alias, entrées invalides")
