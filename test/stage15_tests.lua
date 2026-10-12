local root=arg[1] or "."
local function run(path)
 local chunk,err=loadfile(root.."/"..path)
 assert(chunk,err)
 local previous=arg; arg={root}
 local ok,msg=pcall(chunk)
 arg=previous
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage14_tests.lua")
run("test/stage15_scope_tests.lua")
run("test/stage15_patch_tests.lua")
run("test/stage15_visible_tests.lua")
print("PASS Stage 15 — PATCH 07")
