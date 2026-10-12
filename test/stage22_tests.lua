local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local before=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=before
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage21_tests.lua")
run("test/stage22_scope_tests.lua")
run("test/stage22_synthetic_tests.lua")
run("test/stage22_bigint_tests.lua")
run("test/stage22_real_tests.lua")
run("test/stage22_fault_tests.lua")
run("test/stage22_reentrancy_tests.lua")
run("test/stage22_expected_red_audit.lua")
print("PASS Stage 22 DISCOVERY 11: pozitif QA ak odit EXPECTED_RED")
