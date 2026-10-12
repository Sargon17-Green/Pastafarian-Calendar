local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local G=require("grind_patch")
local L=require("legacy_grinds")
local S=require("spaghetti")
local ref={{3,5,7,11,"w"},{5,7,11,13,"b"},{7,11,13,17,"s"},
 {11,13,17,19,"m"},{13,17,19,23,"r"},{17,19,23,29,"w"},
 {19,23,29,31,"b"},{23,29,31,37,"s"},{29,31,37,41,"m"},
 {31,37,41,43,"r"},{37,41,43,47,"w"}}
local function same(a,b)
 return a and b and a.a==b[1] and a.b==b[2] and a.c==b[3] and
 a.d==b[4] and a.kind==b[5]
end
local rows=G.buildWithSentinel()
assert(rows[0].a==0 and rows[0].b==0 and rows[0].c==0 and rows[0].d==0)
assert(rows[0].kind=="NONE" and rows[12]==nil and #rows==11)
for g=1,11 do
 local expected=ref[g]
 assert(same(rows[g],expected),"Ranje fizik ki mal: "..g)
 assert(same(G.grindRowPatch(g),expected))
 local fixed,ctx=S.grindPatchProbe(g)
 assert(same(fixed,expected))
 assert(ctx.phase=="PATCH_GRIND_INDEX" and ctx.mode=="STAGE_15_PATCH_07")
 assert(ctx.status=="PATCH_GRIND_RETURNED" and ctx.currentHandler=="GRIND_PATCH")
 assert(ctx.previousHandler=="LEGACY_GRIND_INDEX" and ctx.commitToken==2)
 assert(#ctx.branchTrace==2 and ctx.branchTrace[1]=="LEGACY_GRIND_INDEX" and
        ctx.branchTrace[2]=="GRIND_PATCH")
 assert(ctx.pendingSemanticState==nil and ctx.rollbackSnapshot==nil)
 assert(ctx.semanticState.grind==g and ctx.semanticState.origin==1)
 assert(ctx.semanticState.legacyCallPreserved==true)
 assert(ctx.semanticState.sentinelKind=="NONE")
 assert(ctx.semanticState.a==expected[1] and ctx.semanticState.kind==expected[5])
 assert(ctx.metrics["legacy.grind.reads"]==1)
 assert(ctx.metrics["grind.patch.calls"]==1)
 assert(ctx.metrics["grind.patch.sentinelReads"]==1)
 assert(ctx.metrics["grind.patch.realIndex"][1]==tostring(g))
 assert(#ctx.diagnostics==2 and ctx.diagnostics[1].code==
 "GRIND_ROW_SHIFTED_BY_ONE" or g==11 and #ctx.diagnostics==2)
 assert(ctx.diagnostics[2].code=="PATCH_07_SENTINEL_PRESERVES_LEGACY")
 if g<11 then
  local old=L.oldGrindRow(g)
  assert(same(old,ref[g+1]) and not same(old,expected))
  assert(ctx.semanticState.legacyA==ref[g+1][1] and not ctx.semanticState.legacyMissing)
 else
  assert(L.oldGrindRow(g)==nil and ctx.semanticState.legacyMissing)
  assert(ctx.semanticState.legacyA=="MISSING")
 end
 local public=S.grindRowSpaghetti(g)
 assert(same(public,expected))
end
rows[0].kind="BAD";rows[1].a=999
assert(G.buildWithSentinel()[0].kind=="NONE")
assert(G.buildWithSentinel()[1].a==3)
local v,ctx=S.grindPatchProbe(1);v.a=999;ctx.semanticState.a=999
ctx.branchTrace[1]="BAD";ctx.metrics["grind.patch.calls"]=999
local fresh,fctx=S.grindPatchProbe(1)
assert(fresh.a==3 and fctx.semanticState.a==3)
assert(fctx.branchTrace[1]=="LEGACY_GRIND_INDEX" and fctx.metrics["grind.patch.calls"]==1)
for _,invalid in ipairs({0,-1,12,1.5,"1",true,{}}) do
 assert(not pcall(G.grindRowPatch,invalid))
 assert(not pcall(S.grindRowSpaghetti,invalid))
end
print("PASS PATCH 07: sentinel ak 11 ranje, de commits, 11 chemen legacy konsève")
