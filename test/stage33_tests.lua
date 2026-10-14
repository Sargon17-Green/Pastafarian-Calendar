local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local old=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=old
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage32_tests.lua")
run("test/stage33_scope_tests.lua")
run("test/stage33_gap_tests.lua")
run("test/stage33_bigint_tests.lua")
run("test/stage33_fault_tests.lua")
run("test/stage33_reentrancy_tests.lua")
run("test/stage33_real_tests.lua")
print("PASS Stage 33 PATCH 16 native full Stage 1–33 suite")
