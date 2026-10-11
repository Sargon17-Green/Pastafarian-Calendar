local root = arg[1] or "."
local function read(path)
    local file = assert(io.open(root .. "/" .. path, "rb"))
    local data = file:read("*a")
    file:close()
    return data
end
local old = read("src/legacy_save.lua")
assert(old:find("function LegacySave.oldRemainder(value)\n    return BigInt.mod(BigInt.from(value), M)\nend", 1, true))
assert(not old:find("savePatch", 1, true))
local patch = read("src/save_patch.lua")
assert(patch:find("LegacySave.oldRemainder(value)", 1, true))
assert(patch:find("if remainder:isZero() then", 1, true))
assert(patch:find("return BigInt.from(M)", 1, true))
for _, filename in ipairs({"src/save_patch.lua", "src/legacy_save.lua", "src/spaghetti.lua"}) do
    local code = read(filename)
    for _, forbidden in ipairs({"normative_oracle", "oldDayTag", "oldDistance", "oldPermutationUnrank0",
                                "LEGACY_YEAR_MAX", "savePatch02", "mutateStonesWrong"}) do
        assert(not code:find(forbidden, 1, true), filename .. " gen kòd prematire: " .. forbidden)
    end
end
print("PASS limit PATCH 01: legacy pa chanje, oracle rete nan test/")
