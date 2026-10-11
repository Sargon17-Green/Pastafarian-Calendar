local root = arg[1] or "."
local function read(path)
    local file = assert(io.open(root .. "/" .. path, "rb"))
    local data = file:read("*a")
    file:close()
    return data
end
local legacy = read("src/legacy_distance.lua")
assert(legacy:find("function LegacyDistance.oldDistance(calculationDay, targetDay, trace)", 1, true))
assert(legacy:find("DayTagPatch.execute(calculationDay)", 1, true))
assert(legacy:find("DayTagPatch.execute(targetDay)", 1, true))
assert(legacy:find("return BigInt.abs(BigInt.sub(firstTag, secondTag))", 1, true))
assert(legacy:find("LegacyDistance.oldDistance(calculationDay, targetDay, trace)", 1, true))
assert(legacy:find('manager.dispatcher:register("LEGACY_DISTANCE"', 1, true))
local source = read("src/spaghetti.lua")
assert(source:find("local wrong = LegacyDistance.execute(calculationDay, targetDay)", 1, true))
assert(source:find("function S.legacyDistanceProbe(calculationDay, targetDay)", 1, true))
for _, path in ipairs({"src/legacy_distance.lua", "src/spaghetti.lua"}) do
    local text = read(path)
    for _, forbidden in ipairs({"normative_oracle", "distancePatch", "chronologicalDistance",
                                 "oldJumpGuess", "mutateStonesWrong", "LEGACY_YEAR_MAX",
                                 "oldPermutationUnrank0"}) do
        assert(not text:find(forbidden, 1, true), path .. " gen kòd ki twò bonè: " .. forbidden)
    end
end
print("PASS limit Stage 6: chemen legacy reyèl san PATCH 03 ni oracle")
