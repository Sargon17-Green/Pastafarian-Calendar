local root=arg[1] or "."
local old=arg
arg={root}
local chunk=assert(loadfile(root.."/test/stage16_regression_tests.lua"))
local ok,message=pcall(chunk)
arg=old
assert(not ok,"DISCOVERY 08 pa devwale erè factoradic la")
local expected="EXPECTED_RED Stage 16 DISCOVERY 08: 719 rang deplase, rang 720 rejte"
assert(message==expected,"Pa gen egzakteman erè rang istorik la: "..tostring(message))
print("PASS odit EXPECTED_RED Stage 16: 719 deplasman ak rang 720 rejte")
