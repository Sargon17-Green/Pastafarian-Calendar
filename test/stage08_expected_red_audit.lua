local root = arg[1] or "."
local previousArg = arg
arg = {root}
local chunk = assert(loadfile(root .. "/test/stage08_regression_tests.lua"))
local ok, message = pcall(chunk)
arg = previousArg
assert(not ok, "DISCOVERY 04 pa montre erè mutation an")
local expected = "EXPECTED_RED Stage 8 DISCOVERY 04: 4 wòch diferan apre mutation: " ..
    "b: legacy=1434 normative=1073; " ..
    "s: legacy=3780 normative=2375; " ..
    "m: legacy=9932 normative=6195; " ..
    "r: legacy=25047 normative=10493"
assert(message == expected, "Se pa kat diferans wòch ki te prevwa yo: " .. tostring(message))
print("PASS odit EXPECTED_RED Stage 8: 4 wòch, valè egzak")
