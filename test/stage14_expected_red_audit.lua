local root=arg[1] or "."
local before=arg
arg={root}
local chunk=assert(loadfile(root.."/test/stage14_legacy_regression_tests.lua"))
local ok,message=pcall(chunk)
arg=before
assert(not ok,"Discovery 07 pa montre shift ranje grind yo")
local expected="EXPECTED_RED Stage 14 DISCOVERY 07: 11 ranje tounaj mal endekse: 1,2,3,4,5,6,7,8,9,10,11; denye ranje manke"
assert(message==expected,"Li pa erè index tab grind espere a: "..tostring(message))
print("PASS odit EXPECTED_RED Stage 14: 10 ranje deplase, ranje 11 manke")
