local root=arg[1] or "."
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=f:read("*a")
    f:close()
    return s
end
local legacy=read("src/legacy_hidden.lua")
assert(legacy:find("storage[8-k] = value",1,true))
assert(legacy:find("return BigInt.from(storage[k])",1,true))
assert(not legacy:find("HiddenPatch",1,true))
local patch=read("src/hidden_patch.lua")
assert(patch:find("function HiddenPatch.hiddenByNearness(storage, k)",1,true))
assert(patch:find("return LegacyHidden.oldHiddenAt(storage, 8-k)",1,true))
assert(patch:find("local physical, context = LegacyHidden.execute(calculationDay, targetDay)",1,true))
assert(patch:find('manager.dispatcher:register("HIDDEN_PATCH"',1,true))
assert(patch:find('storageOrder = "HIDDEN_7_TO_HIDDEN_1"',1,true))
assert(not patch:find("storage[8-k] =",1,true))
local spaghetti=read("src/spaghetti.lua")
assert(spaghetti:find("local logical = HiddenPatch.execute(calculationDay, targetDay)",1,true))
assert(spaghetti:find("function S.hiddenPatchProbe(calculationDay, targetDay)",1,true))
assert(spaghetti:find("return LegacyHidden.execute(calculationDay, targetDay)",1,true))
for _,path in ipairs({"src/legacy_hidden.lua","src/hidden_patch.lua","src/spaghetti.lua"}) do
    local src=read(path)
    for _,forbidden in ipairs({"normative_oracle", "legacyPrior", "priorPatch",
        "oldPermutationUnrank0", "LEGACY_YEAR_MAX", "VISIBLE_GRINDS"}) do
        assert(not src:find(forbidden,1,true),path..": kòd yon lòt etap: "..forbidden)
    end
end
print("PASS limit PATCH 05: tradiksyon 8-k san ranvèse depo fizik la")
