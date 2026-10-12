local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local before=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=before
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage22_tests.lua")
run("test/stage23_scope_tests.lua")
run("test/stage23_patch_tests.lua")
run("test/stage23_bigint_tests.lua")
run("test/stage23_fault_tests.lua")
run("test/stage23_reentrancy_tests.lua")
run("test/stage23_real_tests.lua")
print("PASS Stage 23 — PATCH 11")