local root=arg[1] or "."
local function run(path)
 local chunk,err=loadfile(root.."/"..path)
 assert(chunk,err)
 local oldArg=arg;arg={root}
 local ok,message=pcall(chunk);arg=oldArg
 if not ok then error(path.." echwe: "..tostring(message),0) end
end
run("test/stage12_tests.lua")
run("test/stage13_scope_tests.lua")
run("test/stage13_patch_tests.lua")
run("test/stage13_context_tests.lua")
run("test/stage13_fault_injection_tests.lua")
print("PASS Stage 13 — PATCH 06")
