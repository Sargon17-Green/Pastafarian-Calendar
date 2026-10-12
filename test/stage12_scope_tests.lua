local root=arg[1] or "."
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"))
    local s=f:read("*a")
    f:close()
    return s
end
local old=read("src/legacy_prior.lua")
assert(old:find("function LegacyPrior.legacyPrior(dropStore, i, back)",1,true))
assert(old:find("return dropStore[i-back]",1,true))
assert(old:find("local hidden, hiddenContext = HiddenPatch.execute(calculationDay, targetDay)",1,true))
assert(old:find("LegacyPrior.legacyPrior(owned, i, back)",1,true))
assert(old:find('manager.dispatcher:register("LEGACY_PRIOR"',1,true))
local public=read("src/spaghetti.lua")
assert(public:find("function S.priorSpaghetti(dropStore, calculationDay, targetDay, i, back)",1,true))
assert(public:find("local value = LegacyPrior.execute(dropStore, calculationDay, targetDay, i, back)",1,true))
assert(public:find("function S.legacyPriorProbe(dropStore, calculationDay, targetDay, i, back)",1,true))
for _,path in ipairs({"src/legacy_prior.lua","src/spaghetti.lua"}) do
    local s=read(path)
    for _,forbidden in ipairs({"normative_oracle", "priorPatch", "hiddenK=1-slot",
       "slot >= 1 then", "oldPermutationUnrank0", "LEGACY_YEAR_MAX", "GRIND_TABLE_WITH_SENTINEL"}) do
       assert(not s:find(forbidden,1,true),path.." gen kòd ki twò bonè: "..forbidden)
    end
end
print("PASS limit Stage 12: history pa konnen hidden, pa gen PATCH 06")
