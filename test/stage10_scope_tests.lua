local root=arg[1] or "."
local function read(p)
    local f=assert(io.open(root.."/"..p,"rb"))
    local s=f:read("*a")
    f:close()
    return s
end
local src=read("src/legacy_hidden.lua")
assert(src:find("storage[8-k] = value",1,true))
assert(src:find("return BigInt.from(storage[k])",1,true))
assert(src:find("DayTagPatch.execute(c)",1,true))
assert(src:find("DayTagPatch.execute(t)",1,true))
assert(src:find("DistancePatch.execute(c, t)",1,true))
assert(src:find("StonePatch.execute(k, current)",1,true))
assert(src:find('manager.dispatcher:register("LEGACY_HIDDEN"',1,true))
local public=read("src/spaghetti.lua")
assert(public:find("function S.hiddenDropsSpaghetti(calculationDay, targetDay)",1,true))
assert(public:find("local logical = HiddenPatch.execute(calculationDay, targetDay)",1,true))
assert(public:find("function S.legacyHiddenProbe(calculationDay, targetDay)",1,true))
for _,path in ipairs({"src/legacy_hidden.lua"}) do
    local s=read(path)
    for _,forbidden in ipairs({"normative_oracle", "coeffForHidden", "hiddenIndexPatch",
                               "legacyPrior", "oldPermutationUnrank0", "LEGACY_YEAR_MAX"}) do
        assert(not s:find(forbidden,1,true),path.." gen kòd twò bonè: "..forbidden)
    end
end
print("PASS limit Stage 10: depo legacy a toujou envèse san oracle")
