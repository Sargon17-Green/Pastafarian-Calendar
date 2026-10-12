local root=arg[1] or "."
local saved=arg;arg={root}
local fn=assert(loadfile(root.."/test/stage22_regression_tests.lua"))
local ok,err=pcall(fn);arg=saved
local exact="EXPECTED_RED Stage 22 DISCOVERY 11: chak gout rekòmanse ak bòl inisyal"
assert(not ok and err==exact,"EXPECTED_RED Stage 22 pa otantik: "..tostring(err))
print("PASS Stage 22 EXPECTED_RED odit: gout 2+ pèdi eta bòl yo")
