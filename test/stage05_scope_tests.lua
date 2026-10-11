local root = arg[1] or "."
local function read(path)
    local f = assert(io.open(root .. "/" .. path, "rb"))
    local data = f:read("*a")
    f:close()
    return data
end
local legacy = read("src/legacy_day_tag.lua")
assert(legacy:find("function LegacyDayTag.oldDayTag(day)", 1, true))
assert(legacy:find("return BigInt.mulSmall(distance, 2)", 1, true))
assert(not legacy:find("dayTagWithFoundationScar", 1, true))
local patch = read("src/day_tag_patch.lua")
assert(patch:find("function DayTagPatch.dayTagWithFoundationScar(day)", 1, true))
assert(patch:find("local n = LegacyDayTag.oldDayTag(day)", 1, true))
assert(patch:find("if day >= FOUNDATION then", 1, true))
assert(patch:find("n = BigInt.add(n, 1)", 1, true))
assert(patch:find("if day == FOUNDATION and BigInt.compare(n, 1) ~= 0 then", 1, true))
assert(patch:find("n = BigInt.from(1)", 1, true))
local spaghetti = read("src/spaghetti.lua")
assert(spaghetti:find("local corrected = DayTagPatch.execute(day)", 1, true))
assert(spaghetti:find("return LegacyDayTag.execute(day)", 1, true))
for _, path in ipairs({"src/legacy_day_tag.lua", "src/day_tag_patch.lua", "src/spaghetti.lua"}) do
    local source = read(path)
    for _, forbidden in ipairs({"normative_oracle", "oldDistance", "mutateStonesWrong",
                                 "LEGACY_YEAR_MAX", "oldPermutationUnrank0", "oldDayTag03"}) do
        assert(not source:find(forbidden, 1, true), path .. " gen yon eleman twò bonè: " .. forbidden)
    end
end
print("PASS limit PATCH 02: ansyen erè a rete, dezyèm guard la prezan, oracle pa nan production")
