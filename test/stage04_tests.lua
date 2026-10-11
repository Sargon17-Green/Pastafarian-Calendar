local root = arg[1] or "."
local function run(path)
    local chunk, err = loadfile(root .. "/" .. path)
    assert(chunk, err)
    local previousArg = arg
    arg = {root}
    local ok, message = pcall(chunk)
    arg = previousArg
    if not ok then error(path .. " echwe: " .. tostring(message), 0) end
end
run("test/stage03_tests.lua")
run("test/stage04_trace_tests.lua")
run("test/stage04_property_tests.lua")
run("test/stage04_scope_tests.lua")
run("test/stage04_expected_red_audit.lua")
run("test/stage04_regression_tests.lua")
