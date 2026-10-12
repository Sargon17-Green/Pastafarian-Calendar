local root=arg[1] or "."
local previous=arg
arg={root}
local chunk=assert(loadfile(root.."/test/stage10_legacy_regression_tests.lua"))
local ok,message=pcall(chunk)
arg=previous
assert(not ok,"Chemen istorik Discovery 05 pa montre erè depo envèse a")
local expected="EXPECTED_RED Stage 10 DISCOVERY 05: 6 hidden drops nan move plas: 1,2,3,5,6,7"
assert(message==expected,"Sa pa sis pozisyon depo istorik yo: "..tostring(message))
print("PASS odit EXPECTED_RED Stage 10: 6 pozisyon ki pa nan lòd")
