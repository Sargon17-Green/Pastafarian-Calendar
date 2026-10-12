local root=arg[1] or "."
local function run(path)
    local chunk, err = loadfile(root .. "/" .. path)
    assert(chunk,err)
    local oldarg=arg
    arg={root}
    local ok,err=pcall(chunk)
    arg=oldarg
    if not ok then error(path.." echwe: "..tostring(err),0) end
end
run("test/stage11_tests.lua")
run("test/stage12_trace_tests.lua")
run("test/stage12_property_tests.lua")
run("test/stage12_scope_tests.lua")
run("test/stage12_fault_injection_tests.lua")
run("test/stage12_expected_red_audit.lua")
run("test/stage12_regression_tests.lua")
