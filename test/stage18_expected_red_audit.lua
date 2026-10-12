local root=arg[1] or "."
local saved=arg
arg={root}
local chunk=assert(loadfile(root.."/test/stage18_regression_tests.lua"))
local ok,err=pcall(chunk)
arg=saved
assert(not ok,"DISCOVERY 09 san difikilte: PATCH 09 antre twò bonè")
local exact="EXPECTED_RED Stage 18 DISCOVERY 09: 3 gout, vide id fiks kont lòd korije"
assert(err==exact,"Stage 18 pa bay bon EXPECTED_RED: "..tostring(err))
print("PASS odit EXPECTED_RED Stage 18: twa premye gout vizib yo rete mal")
