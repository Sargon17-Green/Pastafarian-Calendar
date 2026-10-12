local root=arg[1] or "."
local function read(p)
 local f=assert(io.open(root.."/"..p,"rb"));local t=f:read("*a");f:close();return t
end
local src=read("src/legacy_fixed_neighbor.lua")
local chain=read("src/bowl_chain_patch.lua")
local facade=read("src/spaghetti.lua")
assert(src:find('local bowls,context=Chain.execute(drops,stoneRows,initialBowls)',1,true))
assert(src:find('local order,permCtx=Permutation.execute(drop46)',1,true))
assert(src:find('return queriedId%6+1',1,true))
assert(src:find('local oldNext=Legacy.oldNextBowlFixedName(queriedId)',1,true))
assert(src:find('manager.dispatcher:register("LEGACY_FIXED_NAME_NEIGHBOR"',1,true))
assert(src:find('context.stage23SemanticState=copyData(context.semanticState)',1,true))
assert(facade:find('function S.nextBowlSpaghetti(',1,true))
assert(facade:find('function S.visibleFixedNeighborProbe(',1,true))
assert(chain:find('current=after',1,true))
for _,s in ipairs({src,facade}) do
 for _,word in ipairs({"normative_oracle","postStir12","vaultOld",
      "orderAt46Latch","pendingBowls","neighborPatch","fixedNeighborPatch"}) do
   assert(not s:find(word,1,true),"Etap 25+ antre twò bonè: "..word)
 end
end
print("PASS Stage 24 scope: non fiks 1..6; PATCH 11/08 reyèl; san PATCH 12")
