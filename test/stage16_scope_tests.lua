local root=arg[1] or "."
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=f:read("*a");f:close();return s
end
local src=read("src/legacy_permutation.lua")
assert(src:find("function LegacyPermutation.oldPermutationUnrank0(rank0)",1,true))
assert(src:find("permutation[position] = table.remove(available, index0 + 1)",1,true))
assert(src:find("function LegacyPermutation.oldOrderFromDropWrong(dropValue)",1,true))
assert(src:find("return LegacyPermutation.oldPermutationUnrank0(oneBased)",1,true))
assert(src:find('manager.dispatcher:register("LEGACY_ONE_BASED_RANK"',1,true))
assert(src:find('manager.dispatcher:register("LEGACY_PERM_UNRANK0"',1,true))
local facade=read("src/spaghetti.lua")
assert(facade:find('local LegacyPermutation = require("legacy_permutation")',1,true))
assert(facade:find("function S.permutationSpaghetti(dropValue)",1,true))
assert(facade:find("function S.legacyPermutationProbe(dropValue)",1,true))
assert(not facade:find("oldPermutationUnrank0",1,true),"Stage 1 kadna pa respekte")
for _,path in ipairs({"src/legacy_permutation.lua","src/spaghetti.lua"}) do
    local code=read(path)
    for _,forbidden in ipairs({"normative_oracle","permutationPatch", "orderPatchFromValue",
        "legacyRank0", "bowlAlias", "vaultOld", "orderAt46Latch", "oldNextBowlFixedName"}) do
        assert(not code:find(forbidden,1,true),path.." gen travay ki pou Stage 17 oubyen pita: "..forbidden)
    end
end
print("PASS limit Stage 16: old unrank0 aktif, apèl one-based erone, pa gen PATCH 08")
