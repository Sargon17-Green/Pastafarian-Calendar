local root=arg[1] or "."
local saved=arg;arg={root}
local chunk=assert(loadfile(root.."/test/stage20_regression_tests.lua"))
local ok,err=pcall(chunk)
arg=saved
local exact="EXPECTED_RED Stage 20 DISCOVERY 10: ansyen bòl yo vin alias ak nouvo bòl"
assert(not ok and err==exact,"DISCOVERY 10 pa bay bon EXPECTED_RED: "..tostring(err))
print("PASS Stage 20 odit EXPECTED_RED: alias old/next detekte nan 5 echantiyon")
