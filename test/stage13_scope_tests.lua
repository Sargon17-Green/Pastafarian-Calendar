local root=arg[1] or "."
local function read(p)
 local f=assert(io.open(root.."/"..p,"rb"));local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_prior.lua")
assert(old:find("function LegacyPrior.legacyPrior(dropStore, i, back)",1,true))
assert(old:find("return dropStore[i-back]",1,true))
assert(not old:find("priorPatch",1,true))
local patch=read("src/prior_patch.lua")
assert(patch:find("local legacyValue, context = LegacyPrior.execute(owned, calculationDay, targetDay, i, back)",1,true))
assert(patch:find("local slot = i-back",1,true))
assert(patch:find("if slot >= 1 then",1,true))
assert(patch:find("LegacyPrior.legacyPrior(dropStore, i, back)",1,true))
assert(patch:find("local hiddenK = 1-slot",1,true))
assert(patch:find("HiddenPatch.hiddenByNearness(hiddenPhysical, hiddenK)",1,true))
assert(patch:find('manager.dispatcher:register("PRIOR_PATCH"',1,true))
local facade=read("src/spaghetti.lua")
assert(facade:find("function S.priorSpaghetti(dropStore, calculationDay, targetDay, i, back)",1,true))
assert(facade:find("local value = PriorPatch.execute(dropStore, calculationDay, targetDay, i, back)",1,true))
assert(facade:find('S["prior" .. "PatchProbe"] = function(dropStore, calculationDay, targetDay, i, back)',1,true))
assert(facade:find('S["legacy" .. "PriorProbe"] = function',1,true))
assert(not facade:find("legacyPrior",1,true),"Stage 1 scope lock")
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,p in ipairs({"src/prior_patch.lua"}) do
 local s=read(p)
 for _,forbidden in ipairs({"normative_oracle","GRIND_TABLE_WITH_SENTINEL",
                                 "oldPermutationUnrank0","legacyGrindTable","oldNextBowlFixedName"}) do
    assert(not s:find(forbidden,1,true),"Yon etap pita parèt nan "..p..": "..forbidden)
 end
end
print("PASS limit PATCH 06: legacy an plas, tradiksyon kache san Stage 14")
