local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local prev=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=prev
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage31_tests.lua")
run("test/stage32_scope_tests.lua")
run("test/stage32_trace_tests.lua")
run("test/stage32_bigint_tests.lua")
run("test/stage32_fault_tests.lua")
run("test/stage32_reentrancy_tests.lua")
run("test/stage32_real_tests.lua")
run("test/stage32_expected_red_audit.lua")
print("PASS Stage 32 DISCOVERY 16 positive full native Stage 1–32 suite")
