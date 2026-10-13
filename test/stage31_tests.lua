local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local prev=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=prev
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage30_tests.lua")
run("test/stage31_scope_tests.lua")
run("test/stage31_signed_tests.lua")
run("test/stage31_bigint_tests.lua")
run("test/stage31_fault_tests.lua")
run("test/stage31_reentrancy_tests.lua")
run("test/stage31_real_tests.lua")
print("PASS Stage 31 PATCH 15 full native Stage 1–31 suite")
