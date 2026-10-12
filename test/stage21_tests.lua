local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local before=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=before
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage20_tests.lua")
run("test/stage21_scope_tests.lua")
run("test/stage21_exhaustive_tests.lua")
run("test/stage21_bigint_tests.lua")
run("test/stage21_real_integration_tests.lua")
run("test/stage21_fault_injection_tests.lua")
run("test/stage21_reentrancy_tests.lua")
print("PASS Stage 21 — PATCH 10")
