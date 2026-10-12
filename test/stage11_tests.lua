local root=arg[1] or "."
local function run(path)
    local chunk,err=loadfile(root.."/"..path)
    assert(chunk,err)
    local oldarg=arg
    arg={root}
    local ok,msg=pcall(chunk)
    arg=oldarg
    if not ok then error(path.." echwe: "..tostring(msg),0) end
end
run("test/stage10_tests.lua")
run("test/stage11_scope_tests.lua")
run("test/stage11_index_properties.lua")
run("test/stage11_patch_tests.lua")
run("test/stage11_fault_injection_tests.lua")
print("PASS Stage 11 — PATCH 05")
