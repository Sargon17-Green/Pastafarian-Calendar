local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local BigInt=require("bigint")
local Oracle=require("normative_oracle")
local Spaghetti=require("spaghetti")
local Legacy=require("legacy_hidden")
local Patch=require("hidden_patch")
local F=Oracle.FOUNDATION_DAY
local positions, contexts=0,0

local cases={
    {F,F}, {F-1,F+1}, {F+3,F-2}, {F-20,F-15}, {F+17,F+29},
    {F-125,F-125}, {F+125,F+125}, {F-73,F+137}, {F+137,F-73},
    {F-1000,F-999}, {F+999,F+1000}, {F-2048,F+2048}
}
local seed=1729
for i=1,24 do
    seed=(seed*48271)%2147483647
    local c=F+(seed%20001)-10000
    seed=(seed*48271)%2147483647
    local t=F+(seed%20001)-10000
    cases[#cases+1]={c,t}
end

local function check(c,t,label,doSingles)
    local physical,legacyContext=Spaghetti.legacyHiddenProbe(c,t)
    local logical,context=Spaghetti.hiddenPatchProbe(c,t)
    local public=Spaghetti.hiddenDropsSpaghetti(c,t)
    local normative=Oracle.buildHiddenDrops(Oracle.workCounts(c,t),Oracle.STONES)
    assert(#physical==7 and #logical==7 and #public==7,label..": move longè")
    assert(context~=legacyContext and context.semanticState~=legacyContext.semanticState)
    assert(context.mode=="STAGE_11_PATCH_05" and context.phase=="PATCH_HIDDEN")
    assert(context.status=="PATCH_HIDDEN_RETURNED")
    assert(context.currentHandler=="HIDDEN_PATCH" and context.previousHandler=="LEGACY_HIDDEN")
    assert(#context.branchTrace==2 and context.branchTrace[1]=="LEGACY_HIDDEN" and
           context.branchTrace[2]=="HIDDEN_PATCH")
    assert(context.commitToken==2 and context.pendingSemanticState==nil and
           context.rollbackSnapshot==nil)
    assert(legacyContext.status=="LEGACY_HIDDEN_RETURNED" and legacyContext.commitToken==1)
    assert(context.semanticState.mappingApplied==true)
    assert(context.semanticState.source=="INDEX_TRANSLATION_8_MINUS_K")
    assert(context.semanticState.storageOrder=="HIDDEN_7_TO_HIDDEN_1")
    assert(context.semanticState.calculationDayDecimal==tostring(c))
    assert(context.semanticState.targetDayDecimal==tostring(t))
    assert(context.metrics["legacy.hidden.calls"]==1)
    assert(context.metrics["legacy.hidden.physicalSlots"]==7)
    assert(context.metrics["hidden.patch.calls"]==1)
    assert(context.metrics["hidden.patch.indexTranslations"]==7)
    assert(context.metrics["hidden.patch.nearest"][1]==tostring(logical[1]))
    assert(#context.diagnostics==2)
    assert(context.diagnostics[1].code=="BACKWARDS_HIDDEN_STORAGE_WITH_UNMAPPED_ACCESS")
    assert(context.diagnostics[2].code=="PATCH_05_MAP_8_MINUS_K")
    assert(context.diagnostics[2].physicalOrderPreserved==true)
    assert(context.diagnostics[2].firstPhysicalSlot==tostring(physical[1]))
    assert(context.diagnostics[2].firstLogicalDrop==tostring(logical[1]))
    for k=1,7 do
        local index=8-k
        assert(BigInt.compare(physical[k],normative[index])==0,label..": depo fizik diferan "..k)
        assert(BigInt.compare(logical[k],normative[k])==0,label..": gout normatif diferan "..k)
        assert(BigInt.compare(public[k],logical[k])==0,label..": valè piblik diferan "..k)
        assert(BigInt.compare(Patch.hiddenByNearness(physical,k),logical[k])==0,
               label..": fonksyon endis la pa bay bon gout la "..k)
        assert(BigInt.compare(Legacy.oldHiddenAt(physical,k),normative[index])==0,
               label..": erè legacy a pèdi "..k)
        assert(context.semanticState["physical"..k]==tostring(physical[k]))
        assert(context.semanticState["hidden"..k]==tostring(logical[k]))
        assert(legacyContext.semanticState["physical"..k]==tostring(physical[k]))
        assert(BigInt.compare(logical[k],1)>=0 and BigInt.compare(logical[k],Oracle.M)<=0)
        if doSingles then
            assert(BigInt.compare(Spaghetti.hiddenDropSpaghetti(c,t,k),logical[k])==0,
                   label..": lekti yon sèl gout la "..k)
        end
        positions=positions+1
    end
    -- Eleman mitan an se sèl plas ki pa deplase pandan envèsyon an.
    assert(BigInt.compare(logical[4],physical[4])==0)
    contexts=contexts+1
end
for i,pair in ipairs(cases) do
    check(pair[1],pair[2],"pè "..i,i<=3)
end
assert(contexts==36 and positions==252)

-- Chanje rezilta/kontèks youn pa dwe chanje lòt invocation oswa depo legacy a.
local raw,legacy=Spaghetti.legacyHiddenProbe(F,F)
local corrected,ctx=Spaghetti.hiddenPatchProbe(F,F)
local originalFirst=tostring(raw[1])
local originalLast=tostring(raw[7])
corrected[1]=BigInt.from(999)
ctx.semanticState.hidden1="999"
ctx.semanticState.physical1="999"
ctx.metrics["hidden.patch.calls"]=999
ctx.branchTrace[1]="CHANJE"
ctx.diagnostics[1].code="CHANJE"
assert(tostring(raw[1])==originalFirst and tostring(raw[7])==originalLast)
assert(legacy.semanticState.physical1==originalFirst)
local fresh,freshCtx=Spaghetti.hiddenPatchProbe(F,F)
assert(tostring(fresh[1])==originalLast)
assert(freshCtx.semanticState.hidden1==originalLast)
assert(freshCtx.semanticState.physical1==originalFirst)
assert(freshCtx.metrics["hidden.patch.calls"]==1)
assert(freshCtx.branchTrace[1]=="LEGACY_HIDDEN")
assert(freshCtx.diagnostics[1].code=="BACKWARDS_HIDDEN_STORAGE_WITH_UNMAPPED_ACCESS")

assert(select("#",Spaghetti.hiddenDropsSpaghetti(F,F))==1)
assert(select("#",Spaghetti.hiddenPatchProbe(F,F))==2)
assert(select("#",Spaghetti.legacyHiddenProbe(F,F))==2)
for _,k in ipairs({0,8,-1,1.5,"1",true,{}}) do
    assert(not pcall(Patch.hiddenByNearness,raw,k),"Endis ilegal aksepte")
    assert(not pcall(Spaghetti.hiddenDropSpaghetti,F,F,k),"Endis piblik ilegal aksepte")
end
for _,bad in ipairs({"",1.5,true,{}}) do
    assert(not pcall(Spaghetti.hiddenDropsSpaghetti,bad,F))
    assert(not pcall(Spaghetti.hiddenPatchProbe,F,bad))
end
assert(not pcall(Spaghetti.calendarDateSpaghetti))
print("PASS PATCH 05: "..positions.." pozisyon sou "..contexts..
      " pè, fizik envèse, lekti korije, de commit, izolasyon")
