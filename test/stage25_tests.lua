local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local before=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=before
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage24_tests.lua")
run("test/stage25_scope_tests.lua")
run("test/stage25_exhaustive_tests.lua")
run("test/stage25_patch_tests.lua")
run("test/stage25_bigint_tests.lua")
run("test/stage25_fault_tests.lua")
run("test/stage25_reentrancy_tests.lua")
run("test/stage25_real_tests.lua")
print("PASS Stage 25 — PATCH 12")
