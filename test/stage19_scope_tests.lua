local root=arg[1] or "."
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=f:read("*a");f:close();return s
end
local legacy=read("src/legacy_fixed_pours.lua")
local patch=read("src/pour_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find("local fromFixedBowl=B.from(oldBowls[position])",1,true))
assert(not legacy:find('require("pour_patch")',1,true))
assert(patch:find("local wrong,context=Legacy.execute(drop,index,oldBowls,stoneRow)",1,true))
assert(patch:find("local id=order[position]",1,true))
assert(patch:find("B.mul(stone[NON[position]],old[id])",1,true))
assert(patch:find('manager.dispatcher:register("BOWL_ORDER_POUR_PATCH"',1,true))
assert(facade:find('local PourPatch = require("pour_patch")',1,true))
assert(facade:find("function S.pourPatchProbe(",1,true))
assert(facade:find("local result,context=LegacyFixedPours.execute(drop,1,bowls,stones)",1,true))
assert(facade:find("local corrected,context=PourPatch.execute(drop,1,bowls,stones)",1,true))
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,s in ipairs({patch}) do
    for _,future in ipairs({"normative_oracle","postStir12","orderAt46Latch",
        "vaultOld","oldNextBowlFixedName","pendingBowls"}) do
        assert(not s:find(future,1,true),"Stage 20+ antre twò bonè: "..future)
    end
end
print("PASS limit Stage 19: 3 vide korije, legacy entak, pa gen melanj bòl")
