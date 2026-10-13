local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local save=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=save
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage26_tests.lua")
run("test/stage27_scope_tests.lua")
run("test/stage27_exhaustive_tests.lua")
run("test/stage27_patch_tests.lua")
run("test/stage27_bigint_tests.lua")
run("test/stage27_fault_tests.lua")
run("test/stage27_reentrancy_tests.lua")
run("test/stage27_real_tests.lua")
print("PASS Stage 27 — PATCH 13: full Stage 1–27 native suite")
