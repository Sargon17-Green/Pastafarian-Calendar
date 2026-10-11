local root = arg[1] or "."
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local value = f:read("*a")
    f:close()
    return value
end
local legacy = read("src/legacy_day_tag.lua")
assert(legacy:find("function LegacyDayTag.oldDayTag(day)", 1, true))
assert(legacy:find("BigInt.abs(BigInt.sub(BigInt.from(day), FOUNDATION_BIG))", 1, true))
assert(legacy:find("return BigInt.mulSmall(distance, 2)", 1, true))
local spaghetti = read("src/spaghetti.lua")
assert(spaghetti:find("function S.dayTagSpaghetti(day)", 1, true))
assert(spaghetti:find("local wrong = LegacyDayTag.execute(day)", 1, true))
assert(spaghetti:find("function S.legacyDayTagProbe(day)", 1, true))
for _, path in ipairs({"src/legacy_day_tag.lua", "src/spaghetti.lua"}) do
    local code = read(path)
    for _, forbidden in ipairs({"normative_oracle", "dayTagWithFoundationScar",
                                 "dayTagPatch", "oldDistance", "mutateStonesWrong",
                                 "LEGACY_YEAR_MAX", "oldPermutationUnrank0"}) do
        assert(not code:find(forbidden, 1, true), path .. " gen kòd twò bonè: " .. forbidden)
    end
end
print("PASS limit Discovery 02: pa gen PATCH 02 ni oracle nan production")
