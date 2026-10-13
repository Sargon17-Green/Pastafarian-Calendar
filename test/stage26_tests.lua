local root=arg[1] or "."
local function run(path)
 local fn,err=loadfile(root.."/"..path);assert(fn,err)
 local saved=arg;arg={root}
 local ok,msg=xpcall(fn,debug.traceback);arg=saved
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage25_tests.lua")
run("test/stage26_scope_tests.lua")
run("test/stage26_stream_tests.lua")
run("test/stage26_modulo_tests.lua")
run("test/stage26_fault_tests.lua")
run("test/stage26_reentrancy_tests.lua")
run("test/stage26_expected_red_audit.lua")
print("PASS Stage 26 DISCOVERY 13 positive QA and four EXPECTED_RED audits")
