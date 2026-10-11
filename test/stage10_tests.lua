local root=arg[1] or "."
local function run(path)
    local chunk,err=loadfile(root.."/"..path)
    assert(chunk,err)
    local oldarg=arg
    arg={root}
    local ok,msg=pcall(chunk)
    arg=oldarg
    assert(ok,path.." echwe: "..tostring(msg))
end
run("test/stage09_tests.lua")
run("test/stage10_trace_tests.lua")
run("test/stage10_property_tests.lua")
run("test/stage10_scope_tests.lua")
run("test/stage10_expected_red_audit.lua")
run("test/stage10_regression_tests.lua")
