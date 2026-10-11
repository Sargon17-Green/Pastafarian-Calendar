local root = arg[1] or "."
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local text = f:read("*a")
    f:close()
    return text
end
local legacy = read("src/legacy_distance.lua")
assert(legacy:find("function LegacyDistance.oldDistance(calculationDay, targetDay, trace)", 1, true))
assert(legacy:find("return BigInt.abs(BigInt.sub(firstTag, secondTag))", 1, true))
assert(not legacy:find("DistancePatch", 1, true))
assert(not legacy:find("chronological", 1, true))
local patch = read("src/distance_patch.lua")
assert(patch:find("local legacy, context = LegacyDistance.execute(calculationDay, targetDay)", 1, true))
assert(patch:find("BigInt.abs(BigInt.sub(BigInt.from(targetDay), BigInt.from(calculationDay)))", 1, true))
assert(patch:find("if differed then", 1, true))
assert(patch:find("reconciled = chronological", 1, true))
assert(patch:find("local distance = BigInt.add(reconciled, 1)", 1, true))
assert(patch:find('manager.dispatcher:register("DISTANCE_PATCH"', 1, true))
local spaghetti = read("src/spaghetti.lua")
assert(spaghetti:find("local corrected = DistancePatch.execute(calculationDay, targetDay)", 1, true))
assert(spaghetti:find("function S.distancePatchProbe(calculationDay, targetDay)", 1, true))
assert(spaghetti:find("return LegacyDistance.execute(calculationDay, targetDay)", 1, true))
for _, path in ipairs({"src/legacy_distance.lua", "src/distance_patch.lua", "src/spaghetti.lua"}) do
    local text = read(path)
    for _, forbidden in ipairs({"normative_oracle", "mutateStonesWrong",
                                 "oldPermutationUnrank0", "LEGACY_YEAR_MAX", "oldJumpGuess"}) do
        assert(not text:find(forbidden, 1, true), path .. ": kòd twò bonè " .. forbidden)
    end
end
print("PASS limit PATCH 03: ansyen distans lan pa chanje; koreksyon an swiv kontra a")
