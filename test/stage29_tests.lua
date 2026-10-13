local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local previous=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=previous
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage28_tests.lua")
run("test/stage29_scope_tests.lua")
run("test/stage29_wide_tests.lua")
run("test/stage29_bigint_tests.lua")
run("test/stage29_fault_tests.lua")
run("test/stage29_reentrancy_tests.lua")
run("test/stage29_real_tests.lua")
print("PASS Stage 29 PATCH 14 native full Stage 1–29 suite")
