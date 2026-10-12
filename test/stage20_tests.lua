local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local before=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=before
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage19_tests.lua")
run("test/stage20_scope_tests.lua")
run("test/stage20_synthetic_tests.lua")
run("test/stage20_bigint_tests.lua")
run("test/stage20_real_integration_tests.lua")
run("test/stage20_fault_injection_tests.lua")
run("test/stage20_reentrancy_tests.lua")
run("test/stage20_expected_red_audit.lua")
print("PASS Stage 20 DISCOVERY 10: suite pozitif ak odit EXPECTED_RED")
