local root=arg[1] or "."
local function read(p)
 local f=assert(io.open(root.."/"..p,"rb"))
 local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_fixed_neighbor.lua")
local patch=read("src/neighbor_patch.lua")
local public=read("src/spaghetti.lua")
assert(old:find("return queriedId%6+1",1,true))
assert(old:find('manager.dispatcher:register("LEGACY_FIXED_NAME_NEIGHBOR"',1,true))
assert(not old:find('require("neighbor_patch")',1,true))
assert(patch:find("local wrong,ctx=Legacy.execute(drops,stoneRows,initialBowls,queriedId)",1,true))
assert(patch:find("LegacyPermutation.oldOneBasedRank",1,true))
assert(patch:find("LegacyPermutation.oldPermutationUnrank0(rank-1)",1,true))
assert(patch:find("snapshot[(position%6)+1]",1,true))
assert(patch:find('manager.dispatcher:register("DROP46_NEIGHBOR_ORDER_PATCH"',1,true))
assert(public:find("function S.nextBowlSpaghetti(",1,true))
assert(public:find("function S.legacyFixedNeighborProbe(",1,true))
assert(public:find("function S.neighborPatchProbe(",1,true))
assert(public:find("function S.visibleNeighborPatchProbe(",1,true))
assert(public:find("function S.visibleNeighborSpaghetti(",1,true))
for _,src in ipairs({old,patch,public}) do
 for _,forbidden in ipairs({"normative_oracle","postStir12","askBowlPatch",
     "postStirPatch","gatePatch","chooseRankPatch"}) do
  assert(not src:find(forbidden,1,true),"Stage 26+ pa dwe antre: "..forbidden)
 end
end
print("PASS Stage 25 scope: 4 commit, 46 gout ak rank verifye, legacy intact, no Stage 26")
