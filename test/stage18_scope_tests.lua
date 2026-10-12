local root=arg[1] or "."
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local content=f:read("*a");f:close();return content
end
local fixed=read("src/legacy_fixed_pours.lua")
local facade=read("src/spaghetti.lua")
assert(fixed:find("function LegacyFixedPours.initialBowls",1,true))
assert(fixed:find("function LegacyFixedPours.legacyPoursToFixedBowlIds",1,true))
assert(fixed:find("local order,permutationContext=Permutation.execute(value)",1,true))
assert(fixed:find("local fromFixedBowl=B.from(oldBowls[position])",1,true))
assert(fixed:find('manager.dispatcher:register("LEGACY_FIXED_BOWL_POURS"',1,true))
assert(facade:find("function S.openingPoursSpaghetti",1,true))
assert(facade:find("local drop,visibleContext=S.visibleDropSpaghetti(calculationDay,targetDay,1,{})",1,true))
assert(facade:find("local result,context=LegacyFixedPours.execute(drop,1,bowls,stones)",1,true))
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,s in ipairs({fixed}) do
    for _,forbidden in ipairs({"normative_oracle","bowlAlias","vaultOld",
        "orderAt46Latch","postStir12","oldNextBowlFixedName","pendingBowls"}) do
        assert(not s:find(forbidden,1,true),"Stage 19+ pa dwe antre: "..forbidden)
    end
end
assert(not fixed:find("local fromFixedBowl=B.from(oldBowls[order[position]])",1,true),
       "PATCH 09 antre twò bonè")
print("PASS limit Stage 18: id fizik 1,2,3, rank korije, pa gen PATCH 09")
