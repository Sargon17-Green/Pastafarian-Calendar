local root = arg[1] or "."
local function run(path)
    local chunk, err = loadfile(root .. "/" .. path)
    assert(chunk, err)
    local previousArg = arg
    arg = {root}
    local ok, message = pcall(chunk)
    arg = previousArg
    if not ok then error(path .. " echwe: " .. tostring(message), 0) end
end
run("test/stage02_tests.lua")
run("test/stage03_scope_tests.lua")
run("test/stage03_patch_tests.lua")
print("PASS Stage 3 — PATCH 01")
