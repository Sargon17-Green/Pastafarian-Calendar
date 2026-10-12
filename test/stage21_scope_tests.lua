local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"));local v=f:read("*a");f:close();return v
end
local legacy=read("src/legacy_aliased_stir.lua")
local patch=read("src/stir_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find("local old=working",1,true))
assert(legacy:find("local nextBowls=working",1,true))
assert(not legacy:find('require("stir_patch")',1,true))
assert(patch:find("local wrong,context=Legacy.execute(drop,index,bowls,stones)",1,true))
assert(patch:find("local old=copyBowls(bowls)",1,true))
assert(patch:find("local nextBowls={}",1,true))
assert(patch:find("nextBowls[id]=Save.savePatch(result)",1,true))
assert(patch:find('manager.dispatcher:register("STIR_SNAPSHOT_PATCH"',1,true))
assert(facade:find("function S.stirPatchProbe(",1,true))
assert(facade:find("function S.openingStirPatchProbe(",1,true))
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,text in ipairs({patch}) do
 for _,word in ipairs({"normative_oracle","postStir12","vaultOld",
     "orderAt46Latch","oldNextBowlFixedName","pendingBowls"}) do
   assert(not text:find(word,1,true),"Stage 22+ twò bonè: "..word)
 end
end
print("PASS Stage 21 scope: ansyen alias, nouvo snapshot, pa gen Stage 22")
