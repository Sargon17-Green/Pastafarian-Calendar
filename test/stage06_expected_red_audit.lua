local root = arg[1] or "."
local previousArg = arg
arg = {root}
local chunk = assert(loadfile(root .. "/test/stage06_legacy_regression_tests.lua"))
local ok, message = pcall(chunk)
arg = previousArg
assert(not ok, "Ansyen chemen Discovery 03 pa montre okenn diferans distans istorik")
assert(type(message) == "string", "Regresyon an pa bay yon mesaj verifyab")
local expected = "EXPECTED_RED Stage 6 DISCOVERY 03: 5 ka distance pa ekivalan: " ..
    "SELF: legacy=0 normative=1; " ..
    "ACROSS: legacy=1 normative=3; " ..
    "LONG_BEFORE: legacy=6 normative=4; " ..
    "LONG_AFTER: legacy=6 normative=4; " ..
    "REVERSE_CROSS: legacy=1 normative=3"
assert(message == expected, "Se pa senk diferans distans istorik yo: " .. tostring(message))
print("PASS odit EXPECTED_RED Stage 6: egzakteman 5 diferans distans")
