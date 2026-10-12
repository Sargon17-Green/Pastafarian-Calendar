local root=arg[1] or "."
local function read(p)
    local f=assert(io.open(root.."/"..p,"rb"))
    local s=f:read("*a");f:close();return s
end
local legacy=read("src/legacy_permutation.lua")
local patch=read("src/permutation_patch.lua")
local public=read("src/spaghetti.lua")
assert(legacy:find("return LegacyPermutation.oldPermutationUnrank0(oneBased)",1,true))
assert(not legacy:find('require("permutation_patch")',1,true))
assert(patch:find("local legacyOrder,context=Legacy.execute(dropValue)",1,true))
assert(patch:find("local zeroBased=oneBased-1",1,true))
assert(patch:find("Legacy.oldPermutationUnrank0(zeroBased)",1,true))
assert(patch:find('manager.dispatcher:register("PERMUTATION_PATCH"',1,true))
assert(public:find('local PermutationPatch = require("permutation_patch")',1,true))
assert(public:find("local order = PermutationPatch.execute(dropValue)",1,true))
assert(public:find("return LegacyPermutation.execute(dropValue)",1,true))
for _,src in ipairs({patch,public}) do
    for _,future in ipairs({"bowlAlias","vaultOld","oldNextBowlFixedName","orderAt46Latch",
         "postStir12","normative_oracle"}) do
        assert(not src:find(future,1,true),"Stage 18+ travay antre twò bonè: "..future)
    end
end
print("PASS Stage 17 scope: only permutation rank patch, legacy preserved")
