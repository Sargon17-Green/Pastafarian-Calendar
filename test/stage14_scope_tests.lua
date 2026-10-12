local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local v=f:read("*a");f:close();return v
end
local s=read("src/legacy_grinds.lua")
assert(s:find('[0]={3,5,7,11,"w"}',1,true))
assert(s:find('[10]={37,41,43,47,"w"}',1,true))
assert(s:find("function LegacyGrinds.oldGrindRow(g)",1,true))
assert(s:find("return cloneRow(ORIGINAL_ROWS[g])",1,true))
assert(s:find("LegacyGrinds.execute(g)",1,true))
assert(s:find('manager.dispatcher:register("LEGACY_GRIND_INDEX"',1,true))
assert(s:find("StonePatch.buildPatchedTable()[i]",1,true))
assert(s:find("PriorPatch.execute(dropStore,c,t,i,1)",1,true))
assert(s:find("PriorPatch.execute(dropStore,c,t,i,3)",1,true))
assert(s:find("PriorPatch.execute(dropStore,c,t,i,7)",1,true))
local facade=read("src/spaghetti.lua")
assert(facade:find('local LegacyGrinds = require("legacy_grinds")',1,true))
assert(facade:find('local GrindPatch = require("grind_patch")',1,true))
assert(facade:find("function S.grindRowSpaghetti(grind)",1,true))
assert(facade:find("function S.legacyGrindProbe(grind)",1,true))
assert(facade:find("function S.visibleDropSpaghetti(calculationDay, targetDay, visibleIndex, dropStore)",1,true))
for _,path in ipairs({"src/legacy_grinds.lua"}) do
 local code=read(path)
 for _,forbidden in ipairs({"normative_oracle","GRIND_TABLE_WITH_SENTINEL","GrindPatch",
    "oldPermutationUnrank0","oldNextBowlFixedName","bowlAlias","vaultOld"}) do
  assert(not code:find(forbidden,1,true),path..": kòd Patch 07 oubyen pita: "..forbidden)
 end
end
print("PASS limit Stage 14: zero-based legacy, pa gen sentinel ni Patch 07")
