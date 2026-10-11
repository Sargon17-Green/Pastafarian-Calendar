local root = arg[1] or "."
local productionFiles = {"src/legacy_save.lua", "src/spaghetti.lua"}
local forbidden = {
    "normative_oracle", "savePatch", "SAVE_CORRECTION", "correctedRemainder",
    "LEGACY_YEAR_MAX", "oldDayTag", "oldDistance", "mutateStonesWrong",
    "orderAt46Latch", "oldPermutationUnrank0"
}
for _, relative in ipairs(productionFiles) do
    local f = assert(io.open(root .. "/" .. relative, "rb"))
    local source = f:read("*a")
    f:close()
    for _, marker in ipairs(forbidden) do
        assert(not source:find(marker, 1, true),
               "Kòd patch oswa oracle tonbe nan Stage 2: " .. relative .. " / " .. marker)
    end
end
local moduleFile = assert(io.open(root .. "/src/legacy_save.lua", "rb"))
local legacySource = moduleFile:read("*a")
moduleFile:close()
assert(legacySource:find("function LegacySave.oldRemainder(value)", 1, true))
assert(legacySource:find("return BigInt.mod(BigInt.from(value), M)", 1, true))
print("PASS limit istorik Stage 2: pa gen patch ni import oracle")
