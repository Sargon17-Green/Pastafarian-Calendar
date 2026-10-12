local root=arg[1] or "."
local saved=arg;arg={root}
local fn=assert(loadfile(root.."/test/stage24_regression_tests.lua"))
local ok,err=pcall(fn);arg=saved
local exact="EXPECTED_RED Stage 24 DISCOVERY 12: vwazen pa non fiks inyore lòd gout 46"
assert(not ok and err==exact,"Stage 24 pa gen EXPECTED_RED otantik: "..tostring(err))
print("PASS Stage 24 EXPECTED_RED audit: legacy chwazi 2, oracle chwazi 6 pou rank 720")
