local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_positive_gate_position.lua")
local patch=read("src/positive_gate_patch.lua")
local facade=read("src/spaghetti.lua")
assert(old:find('manager.dispatcher:register("LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"',1,true))
assert(old:find("return B.add(F,gap)",1,true))
assert(not old:find('require("positive_gate_patch")',1,true))
assert(patch:find('local wrong,ctx=Old.execute(index,streams)',1,true))
assert(patch:find('manager.dispatcher:register("POSITIVE_GATE_CUMULATIVE_PATCH"',1,true))
assert(patch:find("for i=1,n-1 do corrected=B.add(corrected,values[i]) end",1,true))
assert(facade:find("function S.legacyPositiveGateProbe(",1,true))
assert(facade:find("function S.positiveGatePatchProbe(",1,true))
assert(facade:find("local repaired=PositiveGatePatch.execute(index,streams)",1,true))
for _,s in ipairs({old,patch,facade}) do
 assert(not s:find("normative_oracle",1,true)
 and not s:find("postStir12",1,true))
end
print("PASS Stage 35 scope: immutable DISCOVERY17, seventh positive cumulative commit, no future gates")
