local root=arg[1] or "."
local function read(path)
  local f=assert(io.open(root.."/"..path,"rb"));local s=f:read("*a");f:close();return s
end
local source=read("src/legacy_aliased_stir.lua")
local facade=read("src/spaghetti.lua")
assert(source:find("local pours,context=Pour.execute(drop,index,bowls,stones)",1,true))
assert(source:find("local old=working",1,true))
assert(source:find("local nextBowls=working",1,true))
assert(source:find("nextBowls[id]=Save.savePatch(v)",1,true))
assert(source:find('manager.dispatcher:register("LEGACY_ALIASED_STIR"',1,true))
assert(not source:find("local nextBowls={}",1,true))
assert(facade:find("function S.openingStirSpaghetti",1,true))
assert(facade:find("function S.legacyAliasedStirProbe",1,true))
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,data in ipairs({source}) do
  for _,future in ipairs({"normative_oracle","postStir12","vaultOld","orderAt46Latch",
       "oldNextBowlFixedName","pendingBowls"}) do
    assert(not data:find(future,1,true),"Stage 21+ antre twò bonè: "..future)
  end
end
print("PASS scope Stage 20: alias brase, PATCH 09 otantik, pa gen PATCH 10")
