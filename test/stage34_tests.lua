local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local old=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=old
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage33_tests.lua")
run("test/stage34_scope_tests.lua")
run("test/stage34_positive_tests.lua")
run("test/stage34_bigint_tests.lua")
run("test/stage34_fault_tests.lua")
run("test/stage34_reentrancy_tests.lua")
run("test/stage34_real_tests.lua")
run("test/stage34_expected_red_audit.lua")
print("PASS Stage 34 DISCOVERY 17 positive full native Stage 1–34 suite")
