local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local L=require("legacy_grinds")
local S=require("spaghetti")
local expected={
 {3,5,7,11,"w"},{5,7,11,13,"b"},{7,11,13,17,"s"},
 {11,13,17,19,"m"},{13,17,19,23,"r"},{17,19,23,29,"w"},
 {19,23,29,31,"b"},{23,29,31,37,"s"},{29,31,37,41,"m"},
 {31,37,41,43,"r"},{37,41,43,47,"w"}
}
local function same(row, ref)
 if not row or not ref then return row==ref end
 return row.a==ref[1] and row.b==ref[2] and row.c==ref[3] and
        row.d==ref[4] and row.kind==ref[5]
end
for g=1,11 do
 local row,ctx=S.legacyGrindProbe(g)
 assert(ctx.mode=="STAGE_14_DISCOVERY_07")
 assert(ctx.phase=="LEGACY_GRIND_INDEX")
 assert(ctx.currentHandler=="LEGACY_GRIND_INDEX")
 assert(ctx.commitToken==1 and ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(#ctx.branchTrace==1 and ctx.branchTrace[1]=="LEGACY_GRIND_INDEX")
 assert(ctx.semanticState.grind==g and ctx.semanticState.physicalIndex==g)
 assert(ctx.semanticState.tableOrigin==0 and ctx.semanticState.expectedOrigin==1)
 assert(ctx.metrics["legacy.grind.reads"]==1)
 assert(ctx.metrics["legacy.grind.index"][1]==tostring(g))
 assert(#ctx.diagnostics==1)
 local public=S.grindRowSpaghetti(g)
 if g<=10 then
  assert(same(row,expected[g+1]),"Ranje legacy a pa deplase nan "..g)
  assert(not same(row,expected[g]),"Ranje legacy a korije twò bonè nan "..g)
  assert(same(public,expected[g+1]))
  assert(ctx.status=="LEGACY_GRIND_RETURNED" and ctx.semanticState.missing==false)
  assert(ctx.diagnostics[1].code=="GRIND_ROW_SHIFTED_BY_ONE")
  assert(ctx.metrics["legacy.grind.missingTail"]==nil)
 else
  assert(row==nil and public==nil)
  assert(ctx.status=="LEGACY_GRIND_MISSING" and ctx.semanticState.missing==true)
  assert(ctx.diagnostics[1].code=="GRIND_11_ROW_MISSING")
  assert(ctx.metrics["legacy.grind.missingTail"]==1)
 end
end
for slot=0,10 do
 local original=L.originalPhysicalRow(slot)
 assert(same(original,expected[slot+1]),"Ranje fizik la mal nan "..slot)
end
-- Pwopriyetè done ak izolasyon ant apèl yo.
local copy=L.oldGrindRow(1)
copy.a=999;copy.kind="NO"
local after,ctx=S.legacyGrindProbe(1)
ctx.semanticState.a=999;ctx.diagnostics[1].code="NO"
assert(after.a==5 and after.kind=="b")
local fresh,other=S.legacyGrindProbe(1)
assert(fresh.a==5 and fresh.kind=="b")
assert(other.semanticState.a==5 and other.diagnostics[1].code=="GRIND_ROW_SHIFTED_BY_ONE")
for _,bad in ipairs({0,-1,12,1.5,"1",true,{}}) do
 assert(not pcall(L.oldGrindRow,bad))
 assert(not pcall(S.grindRowSpaghetti,bad))
end
for _,bad in ipairs({-1,11,0.5,"0",true,{}}) do
 assert(not pcall(L.originalPhysicalRow,bad))
end
print("PASS pwopriyete Stage 14: 10 ranje avanse, 1 ranje manke, 11 fizik, izolasyon")
