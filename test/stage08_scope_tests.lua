local root = arg[1] or "."
local function read(p)
    local f = assert(io.open(root .. "/" .. p, "rb"))
    local s = f:read("*a")
    f:close()
    return s
end
local legacy = read("src/legacy_stones.lua")
assert(legacy:find("function LegacyStones.mutateStonesWrong(i, S)", 1, true))
assert(legacy:find("S.b = SavePatch.savePatch", 1, true))
assert(legacy:find("BigInt.mulSmall(BigInt.from(S.s), 5)), S.w)", 1, true))
assert(legacy:find("BigInt.mulSmall(BigInt.from(S.m), 7)), S.b)", 1, true))
assert(legacy:find("BigInt.mulSmall(BigInt.from(S.r), 11)), S.s)", 1, true))
assert(legacy:find("BigInt.mulSmall(S.w, 13)), S.m)", 1, true))
assert(legacy:find("LegacyStones.mutateStonesWrong(i, wrong)", 1, true))
assert(legacy:find('manager.dispatcher:register("LEGACY_STONES"', 1, true))
local spaghetti = read("src/spaghetti.lua")
assert(spaghetti:find("function S.stoneSpaghetti(index, stones)", 1, true))
assert(spaghetti:find("local corrected = StonePatch.execute(index, stones)", 1, true))
assert(spaghetti:find("function S.stoneTableSpaghetti()", 1, true))
for _, p in ipairs({"src/legacy_stones.lua"}) do
    local s = read(p)
    for _, forbidden in ipairs({"normative_oracle", "stonePatch", "buildStonesCorrected",
                                 "oldDistance04", "oldPermutationUnrank0", "LEGACY_YEAR_MAX"}) do
        assert(not s:find(forbidden, 1, true), p .. " gen kòd twò bonè: " .. forbidden)
    end
end
print("PASS limit Stage 8: kalkil legacy a san patch ni oracle")
