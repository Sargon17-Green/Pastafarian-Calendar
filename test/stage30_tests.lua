local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local previous=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=previous
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage29_tests.lua")
run("test/stage30_scope_tests.lua")
run("test/stage30_trace_tests.lua")
run("test/stage30_properties_tests.lua")
run("test/stage30_fault_tests.lua")
run("test/stage30_reentrancy_tests.lua")
run("test/stage30_real_tests.lua")
run("test/stage30_expected_red_audit.lua")
print("PASS Stage 30 DISCOVERY 15 full positive Stage 1–30 suite")
