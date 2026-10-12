local root=arg[1] or "."
local function run(p)
    local chunk,err=loadfile(root.."/"..p)
    assert(chunk,err)
    local saved=arg;arg={root}
    local ok,message=pcall(chunk);arg=saved
    if not ok then error(p.." echwe: "..tostring(message),0) end
end
run("test/stage17_tests.lua")
run("test/stage18_scope_tests.lua")
run("test/stage18_initial_bowls_tests.lua")
run("test/stage18_pours_tests.lua")
run("test/stage18_visible_tests.lua")
run("test/stage18_expected_red_audit.lua")
print("PASS tès pozitif Stage 18 ak odit EXPECTED_RED")
