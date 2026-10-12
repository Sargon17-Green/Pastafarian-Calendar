local root=arg[1] or "."
local function read(p)
 local f=assert(io.open(root.."/"..p,"rb"));local s=f:read("*a");f:close();return s
end
local legacy=read("src/legacy_grinds.lua")
assert(legacy:find('[0]={3,5,7,11,"w"}',1,true))
assert(legacy:find('return cloneRow(ORIGINAL_ROWS[g])',1,true))
assert(not legacy:find('GrindPatch',1,true))
local patch=read("src/grind_patch.lua")
assert(patch:find('rows={[0]={a=0,b=0,c=0,d=0,kind="NONE"}}',1,true))
assert(patch:find('rows[g]=LegacyGrinds.originalPhysicalRow(g-1)',1,true))
assert(patch:find('local wrong, context=LegacyGrinds.execute(g)',1,true))
assert(patch:find('LegacyGrinds.oldGrindRow(g)',1,true))
assert(patch:find('manager.dispatcher:register("GRIND_PATCH"',1,true))
assert(patch:find('local p1=assert(PriorPatch.execute(dropStore,c,t,i,1)',1,true))
assert(patch:find('for g=1,11 do',1,true))
local public=read("src/spaghetti.lua")
assert(public:find('local GrindPatch = require("grind_patch")',1,true))
assert(public:find('local row = GrindPatch.execute(grind)',1,true))
assert(public:find('return GrindPatch.visibleDropPatched(calculationDay, targetDay, visibleIndex, dropStore)',1,true))
assert(public:find('return LegacyGrinds.visibleDropLegacy(calculationDay, targetDay, visibleIndex, dropStore)',1,true))
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,p in ipairs({"src/grind_patch.lua"}) do
 local s=read(p)
 for _,forbidden in ipairs({"normative_oracle", "oldPermutationUnrank0", "bowlAlias",
 "oldNextBowlFixedName", "vaultOld", "orderAt46Latch"}) do
   assert(not s:find(forbidden,1,true),p.." gen etap lavni: "..forbidden)
 end
end
print("PASS limit Stage 15: sentinel 0, onz ranje, legacy konsève")
