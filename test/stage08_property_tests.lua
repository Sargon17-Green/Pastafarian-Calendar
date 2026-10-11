local root = arg[1] or "."
package.path = root .. "/src/?.lua;" .. root .. "/test/?.lua;" .. package.path
local B = require("bigint")
local O = require("normative_oracle")
local S = require("spaghetti")
local L = require("legacy_stones")
local names = {"w", "b", "s", "m", "r"}

local function snapshotStep(i, old)
    local w,b,s,m,r = old.w,old.b,old.s,old.m,old.r
    return {
        w = O.SAVE(B.mul(w,w) + B.mulSmall(b,3) + B.from(i)),
        b = O.SAVE(B.mul(b,b) + B.mulSmall(s,5) + w),
        s = O.SAVE(B.mul(s,s) + B.mulSmall(m,7) + b),
        m = O.SAVE(B.mul(m,m) + B.mulSmall(r,11) + s),
        r = O.SAVE(B.mul(r,r) + B.mulSmall(w,13) + m)
    }
end

-- Referans pou ansyen chemen an: emile lòd depandans yo san rele production.
local function sequentialStep(i, old)
    local w,b,s,m,r = old.w,old.b,old.s,old.m,old.r
    local nw = O.SAVE(B.mul(w,w) + B.mulSmall(b,3) + B.from(i))
    local nb = O.SAVE(B.mul(b,b) + B.mulSmall(s,5) + nw)
    local ns = O.SAVE(B.mul(s,s) + B.mulSmall(m,7) + nb)
    local nm = O.SAVE(B.mul(m,m) + B.mulSmall(r,11) + ns)
    local nr = O.SAVE(B.mul(r,r) + B.mulSmall(nw,13) + nm)
    return {w=nw,b=nb,s=ns,m=nm,r=nr}
end

local checked, unequalRows = 0, 0
local function same(a, b)
    for _,name in ipairs(names) do
        if B.compare(a[name], b[name]) ~= 0 then return false end
    end
    return true
end
local function verify(i, input, label)
    local untouched = L.copy(input)
    local wrong, ctx = S.legacyStoneProbe(i, input)
    local public = S.stoneSpaghetti(i, input)
    local sequential = sequentialStep(i, untouched)
    local normative = snapshotStep(i, untouched)
    assert(same(wrong, sequential), label .. ": move rezilta mutation sekan")
    assert(same(public, normative), label .. ": wout piblik la pa korije")
    assert(B.compare(wrong.w, normative.w) == 0, label .. ": premye wòch")
    assert(ctx.commitToken == 1 and ctx.status == "LEGACY_STONES_RETURNED")
    assert(ctx.pendingSemanticState == nil and ctx.rollbackSnapshot == nil)
    for _,name in ipairs(names) do
        assert(B.compare(input[name], untouched[name]) == 0, label .. ": modifye antre")
        assert(B.compare(wrong[name], 1) >= 0 and B.compare(wrong[name], O.M) <= 0,
               label .. ": soti SAVE deyò entèval la")
        assert(ctx.semanticState[name] == tostring(wrong[name]))
    end
    if not same(wrong, normative) then unequalRows = unequalRows + 1 end
    checked = checked + 1
end

-- Tout 45 tranzisyon ki devlope tablo pwodiksyon an reyèlman.
local tableStones = S.stoneTableSpaghetti()
local legacyTable = L.buildLegacyTable()
assert(#tableStones == 46)
local starting = L.seed()
assert(same(tableStones[1], starting))
assert(same(legacyTable[1], starting))
local oldNormative = L.copy(starting)
for i = 2, 46 do
    verify(i, legacyTable[i-1], "ranje legacy " .. i)
    local legacyExpected = sequentialStep(i, legacyTable[i-1])
    assert(same(legacyTable[i], legacyExpected), "Tablo legacy pa swiv mutasyon an")
    oldNormative = snapshotStep(i, oldNormative)
    assert(same(tableStones[i], oldNormative), "Tablo production pa swiv snapshot la")
end
assert(not same(legacyTable[2], snapshotStep(2, starting)))
assert(not same(legacyTable[46], oldNormative))
local another = S.stoneTableSpaghetti()
tableStones[2].w = B.from(999)
assert(same(another[2], snapshotStep(2, starting)), "Kach oswa alias tab wòch yo")

-- Gri 5 x 5 x 5: modil ak siy diferan sou senk kote yo.
local sample = {"0", "1", "-1", "170141183460469231731687303715884105727",
                "1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"}
for w=1,5 do
    for b=1,5 do
        for s=1,5 do
            local input={w=sample[w],b=sample[b],s=sample[s],
                         m=sample[(w+b)%5+1],r=sample[(w+s)%5+1]}
            verify(2+(w+b+s)%45, input, "gri "..w..","..b..","..s)
        end
    end
end

-- Antye gwo ki pa limite a 256 bit, avèk gwo endis legal yo.
local state = 12931
local function digit()
    state = (state*48271)%2147483647
    return state%10
end
local function decimal(length)
    local a={tostring(1 + (digit()%9))}
    for i=2,length do a[#a+1]=tostring(digit()) end
    return table.concat(a)
end
for i=1,240 do
    local size=1+(i*29)%130
    local input={}
    for j,name in ipairs(names) do
        local x=decimal(size+(j-1)*3)
        if (i+j)%4 == 0 then x="-"..x end
        input[name]=x
    end
    verify(2+(i*17)%45, input, "antye repwodiktib "..i)
end
assert(checked==410, "Kantite tès pwopriyete yo chanje")
assert(unequalRows>300, "Diferans snapshot yo pa parèt ase")
print("PASS pwopriyete Stage 8: " .. checked .. " tranzisyon, " .. unequalRows ..
      " diferan; 46 ranje ak >256 bit")
