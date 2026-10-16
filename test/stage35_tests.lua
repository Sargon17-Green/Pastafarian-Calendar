local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local old=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=old
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage34_tests.lua")
run("test/stage35_scope_tests.lua")
run("test/stage35_positive_tests.lua")
run("test/stage35_properties_tests.lua")
run("test/stage35_bigint_tests.lua")
run("test/stage35_fault_tests.lua")
run("test/stage35_reentrancy_tests.lua")
run("test/stage35_real_tests.lua")
print("PASS Stage 35 PATCH 17 full native Stage 1–35 suite")
