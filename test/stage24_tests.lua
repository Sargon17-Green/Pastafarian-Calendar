local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local before=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=before
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage23_tests.lua")
run("test/stage24_scope_tests.lua")
run("test/stage24_exhaustive_tests.lua")
run("test/stage24_synthetic_tests.lua")
run("test/stage24_bigint_tests.lua")
run("test/stage24_fault_tests.lua")
run("test/stage24_reentrancy_tests.lua")
run("test/stage24_real_tests.lua")
run("test/stage24_expected_red_audit.lua")
print("PASS Stage 24 DISCOVERY 12: pozitif QA, EXPECTED_RED odit")
