local root=arg[1] or "."
local function run(path)
 local chunk,err=loadfile(root.."/"..path)
 assert(chunk,err)
 local old=arg;arg={root}
 local ok,msg=pcall(chunk);arg=old
 if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage13_tests.lua")
run("test/stage14_scope_tests.lua")
run("test/stage14_property_tests.lua")
run("test/stage14_visible_smoke_tests.lua")
run("test/stage14_expected_red_audit.lua")
run("test/stage14_regression_tests.lua")
