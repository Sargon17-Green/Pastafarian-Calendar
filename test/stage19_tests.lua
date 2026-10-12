local root=arg[1] or "."
local function run(path)
    local chunk,err=loadfile(root.."/"..path)
    assert(chunk,err)
    local saved=arg;arg={root}
    local ok,msg=pcall(chunk);arg=saved
    if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage18_tests.lua")
run("test/stage19_scope_tests.lua")
run("test/stage19_exhaustive_tests.lua")
run("test/stage19_bigint_tests.lua")
run("test/stage19_real_integration_tests.lua")
run("test/stage19_fault_injection_tests.lua")
run("test/stage19_isolation_tests.lua")
print("PASS Stage 19 — PATCH 09")
