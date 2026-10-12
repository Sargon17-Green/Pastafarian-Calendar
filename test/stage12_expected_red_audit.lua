local root = arg[1] or "."
local previous = arg
arg = {root}
local chunk = assert(loadfile(root .. "/test/stage12_legacy_regression_tests.lua"))
local ok, message = pcall(chunk)
arg = previous
assert(not ok,"DISCOVERY 06 pa montre erè history a")
local expected = "EXPECTED_RED Stage 12 DISCOVERY 06: 7 hidden prior manke: 0,-1,-2,-3,-4,-5,-6"
assert(message==expected,"Erè a pa soti nan sèt mank history yo: " .. tostring(message))
print("PASS odit EXPECTED_RED Stage 12: sèt plas hidden pa rezoud")
