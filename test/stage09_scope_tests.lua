local root = arg[1] or "."
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local result = f:read("*a")
    f:close()
    return result
end
local old = read("src/legacy_stones.lua")
assert(old:find("function LegacyStones.mutateStonesWrong(i, S)", 1, true))
assert(old:find("S.b = SavePatch.savePatch", 1, true))
assert(old:find("LegacyStones.mutateStonesWrong(i, wrong)", 1, true))
assert(not old:find("StonePatch", 1, true))
local patch = read("src/stone_patch.lua")
assert(patch:find("local old = LegacyStones.copy(stones)", 1, true))
assert(patch:find("LegacyStones.mutateStonesWrong(i, LegacyStones.copy(old))", 1, true))
assert(patch:find("LegacyStones.execute(i, LegacyStones.copy(old))", 1, true))
assert(patch:find("local legacyBeforeOverwrite = LegacyStones.copy(garbage)", 1, true))
for _, name in ipairs({"w","b","s","m","r"}) do
    assert(patch:find("garbage." .. name .. " = SavePatch.savePatch", 1, true),
           "Patch la dwe ranplase tout senk wòch yo: " .. name)
end
assert(patch:find('manager.dispatcher:register("STONE_PATCH"', 1, true))
local public = read("src/spaghetti.lua")
assert(public:find("local corrected = StonePatch.execute(index, stones)", 1, true))
assert(public:find("function S.stonePatchProbe(index, stones)", 1, true))
assert(public:find("return LegacyStones.execute(index, stones)", 1, true))
assert(public:find("return StonePatch.buildPatchedTable()", 1, true))
for _, path in ipairs({"src/legacy_stones.lua", "src/stone_patch.lua", "src/spaghetti.lua"}) do
    local src = read(path)
    for _, forbidden in ipairs({"normative_oracle", "oldDistance04",
        "LEGACY_YEAR_MAX", "oldPermutationUnrank0", "legacyPrior", "hidden7"}) do
        assert(not src:find(forbidden, 1, true), path .. ": twò bonè " .. forbidden)
    end
end
print("PASS limit PATCH 04: senk ranplasman, legacy orijinal ak oracle separe")
