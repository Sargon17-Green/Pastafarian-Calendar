local root=arg[1] or "."
local function read(path)
 local f=assert(io.open(root.."/"..path,"rb"))
 local s=f:read("*a");f:close();return s
end
local old=read("src/legacy_positive_gate_position.lua")
local facade=read("src/spaghetti.lua")
assert(old:find('local GateGap=require("gate_gap_patch")',1,true)
 and old:find('local gap,child=GateGap.execute(i,source.first,source.directionStep)',1,true)
 and old:find('local old=Legacy.oldPositivePosition(gaps[n])',1,true)
 and old:find('return B.add(F,gap)',1,true)
 and old:find('manager.dispatcher:register("LEGACY_POSITIVE_GATE_RESETS_FOUNDATION"',1,true)
 and old:find('active:commitSemanticUpdate()',1,true)
 and not old:find('require("positive_gate_patch")',1,true))
assert(facade:find("function S.legacyPositiveGateProbe(",1,true)
 and facade:find("function S.positiveGateDaySpaghetti(",1,true))
for _,s in ipairs({old,facade}) do
 assert(not s:find("normative_oracle",1,true)
  and not s:find("postStir12",1,true))
end
print("PASS Stage 34 scope: authentic PATCH16 gaps, legacy reset F+lastgap, sixth commit, no PATCH17")
