local root=arg[1] or "."
local function run(path)
    local chunk,err=loadfile(root.."/"..path)
    assert(chunk,err)
    local previous=arg;arg={root}
    local ok,message=pcall(chunk);arg=previous
    if not ok then error(path.." echwe: "..tostring(message),0) end
end
run("test/stage15_tests.lua")
run("test/stage16_scope_tests.lua")
run("test/stage16_factoradic_tests.lua")
run("test/stage16_property_tests.lua")
run("test/stage16_boundary_tests.lua")
run("test/stage16_periodicity_tests.lua")
run("test/stage16_interleaving_tests.lua")
run("test/stage16_reentrancy_tests.lua")
run("test/stage16_fault_injection_tests.lua")
run("test/stage16_error_identity_tests.lua")
run("test/stage16_authentic_validation_tests.lua")
run("test/stage16_visible_integration_tests.lua")
run("test/stage16_expected_red_audit.lua")
run("test/stage16_regression_tests.lua")
