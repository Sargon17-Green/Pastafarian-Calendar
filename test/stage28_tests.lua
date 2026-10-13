local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local previous=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=previous
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage27_tests.lua")
run("test/stage28_scope_tests.lua")
run("test/stage28_short_tests.lua")
run("test/stage28_wide_tests.lua")
run("test/stage28_bigint_tests.lua")
run("test/stage28_fault_tests.lua")
run("test/stage28_reentrancy_tests.lua")
run("test/stage28_real_tests.lua")
run("test/stage28_expected_red_audit.lua")
print("PASS Stage 28 DISCOVERY 14 positive full QA and intentional-red audit")
