local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local v=f:read("*a");f:close();return v
end
local source=read("src/legacy_reset_chain.lua")
local facade=read("src/spaghetti.lua")
assert(source:find('local nextBowls,child=StirPatch.execute(',1,true))
assert(source:find('values[i],i,restartedFrom,rocks[i])',1,true))
assert(source:find('local restartedFrom=copySix(original)',1,true))
assert(source:find('previousOutput=copySix(nextBowls)',1,true))
assert(not source:find('copySix(previousOutput)',1,true))
assert(source:find('manager.dispatcher:register("LEGACY_BOWL_STATE_RESET"',1,true))
assert(facade:find("function S.visibleResetChainProbe(",1,true))
assert(facade:find("function S.legacyResetBowlsProbe(",1,true))
-- Etap sa a pwoteje modil istorik li; facade a gen dwa grandi nan etap pita.
for _,txt in ipairs({source}) do
 for _,later in ipairs({"normative_oracle","postStir12","orderAt46Latch",
     "vaultOld","oldNextBowlFixedName","pendingBowls"}) do
   assert(not txt:find(later,1,true),"Stage 23+ twò bonè: "..later)
 end
end
print("PASS Stage 22 scope: gout kouri PATCH 10, eta inisyal reaplike")
