local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local H=require("legacy_hidden")
local F=O.FOUNDATION_DAY

local raw,ctx=S.legacyHiddenProbe(F,F)
assert(#raw==7 and select("#",S.hiddenDropsSpaghetti(F,F))==1)
assert(select("#",S.legacyHiddenProbe(F,F))==2)
assert(ctx.mode=="STAGE_10_DISCOVERY_05" and ctx.phase=="LEGACY_HIDDEN")
assert(ctx.status=="LEGACY_HIDDEN_RETURNED" and ctx.currentHandler=="LEGACY_HIDDEN")
assert(ctx.commitToken==1 and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
assert(#ctx.branchTrace==1 and ctx.branchTrace[1]=="LEGACY_HIDDEN")
assert(ctx.metrics["legacy.hidden.calls"]==1)
assert(ctx.metrics["legacy.hidden.physicalSlots"]==7)
assert(ctx.metrics["legacy.hidden.firstSlot"][1]==tostring(raw[1]))
assert(ctx.semanticState.storageOrder=="HIDDEN_7_TO_HIDDEN_1")
assert(ctx.semanticState.source=="HIDDEN_DROPS_REVERSED_PHYSICAL_STORAGE")
assert(ctx.semanticState.calculationDayDecimal==tostring(F))
assert(ctx.semanticState.targetDayDecimal==tostring(F))
assert(#ctx.diagnostics==1 and ctx.diagnostics[1].code==
       "BACKWARDS_HIDDEN_STORAGE_WITH_UNMAPPED_ACCESS")
local expected={
    "6164285870955721082771365327359496898",
    "73551520026920072430116213847585486272",
    "81202913407267092008896220686064041568",
    "166629231917547214614573522551290204247",
    "24217814924229232987463457533828175476",
    "11877236279154673426874867061566696749",
    "119390830530032782664128530203002080344"
}
for k=1,7 do
    assert(tostring(raw[k])==expected[k],"Depo fizik diferan: "..k)
    assert(ctx.semanticState["physical"..k]==expected[k])
    assert(B.compare(H.oldHiddenAt(raw,k),raw[k])==0)
end
assert(tostring(S.hiddenDropSpaghetti(F,F,1))==expected[7])
assert(tostring(S.hiddenDropSpaghetti(F,F,4))==expected[4])
local corrected = S.hiddenDropsSpaghetti(F,F)
for k=1,7 do assert(tostring(corrected[k])==expected[8-k]) end
assert(tostring(S.hiddenDropSpaghetti(F,F,7))==expected[1])
-- Chak apèl posede yon nouvo kontèks, yon depo ak tout BigInt yo.
raw[1]=B.from(5)
ctx.semanticState.physical1="CHANJE"
ctx.branchTrace[1]="CHANJE"
ctx.diagnostics[1].code="CHANJE"
ctx.metrics["legacy.hidden.calls"]=999
local again,other=S.legacyHiddenProbe(F,F)
assert(tostring(again[1])==expected[1])
assert(other.semanticState.physical1==expected[1])
assert(other.branchTrace[1]=="LEGACY_HIDDEN")
assert(other.diagnostics[1].code=="BACKWARDS_HIDDEN_STORAGE_WITH_UNMAPPED_ACCESS")
assert(other.metrics["legacy.hidden.calls"]==1)
for _,bad in ipairs({"",true,{},1.5}) do
    assert(not pcall(S.hiddenDropsSpaghetti,bad,F))
    assert(not pcall(S.hiddenDropsSpaghetti,F,bad))
end
for _,bad in ipairs({0,8,-1,1.5,"1",true,{}}) do
    assert(not pcall(S.hiddenDropSpaghetti,F,F,bad))
end
assert(not pcall(S.calendarDateSpaghetti))
print("PASS tras Stage 10: 7 valè egzak, dispatcher, eta, alias, validasyon")
