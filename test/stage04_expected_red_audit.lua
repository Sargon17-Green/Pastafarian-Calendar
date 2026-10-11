local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local previousArg = arg
arg = {root}
local chunk = assert(loadfile(root .. "/test/stage04_legacy_regression_tests.lua"))
local ok, message = pcall(chunk)
arg = previousArg
assert(not ok, "Ansyen chemen Discovery 02 pa montre diferans istorik yo ankò")
assert(type(message) == "string")
local expected = "EXPECTED_RED Stage 4 DISCOVERY 02: 4 ka dayTag pa ekivalan: " ..
                 "FOUNDATION: legacy=0 normative=1; " ..
                 "AFTER_1: legacy=2 normative=3; " ..
                 "AFTER_2: legacy=4 normative=5; " ..
                 "AFTER_20: legacy=40 normative=41"
assert(message == expected, "Se pa diferans dayTag yo sèlman: " .. message)
print("PASS odit EXPECTED_RED Stage 4: egzakteman 4 diferans sa yo")
