local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local t=f:read("*a");f:close();return t
end
local legacy=read("src/legacy_reset_chain.lua")
local patch=read("src/bowl_chain_patch.lua")
local facade=read("src/spaghetti.lua")
assert(legacy:find('local restartedFrom=copySix(original)',1,true))
assert(legacy:find('values[i],i,restartedFrom,rocks[i])',1,true))
assert(not legacy:find('require("bowl_chain_patch")',1,true))
assert(patch:find('local wrong,ctx=Legacy.execute(drops,stoneRows,initialBowls)',1,true))
assert(patch:find('local corrected,child=Stir.execute(values[i],i,before,rocks[i])',1,true))
assert(patch:find('current=after',1,true))
assert(patch:find('manager.dispatcher:register("BOWL_CHAIN_STATE_PATCH"',1,true))
assert(facade:find('function S.bowlChainPatchProbe(',1,true))
assert(facade:find('function S.visibleBowlChainPatchProbe(',1,true))
for _,s in ipairs({legacy,patch,facade}) do
 for _,word in ipairs({"normative_oracle","postStir12","orderAt46Latch",
    "vaultOld","oldNextBowlFixedName","pendingBowls"}) do
   assert(not s:find(word,1,true),"Stage 24+ twò bonè: "..word)
 end
end
print("PASS Stage 23 scope: legacy reset konsève, chèn sis bòl korije, san Stage 24")