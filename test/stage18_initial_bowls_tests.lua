local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local F=O.FOUNDATION_DAY
local pairs={{F,F},{F+1,F-1},{F-5,F+9},{F-73,F+137},
    {F+137,F-73},{F-1000,F+999},{F+10000,F+10001},{F-10000,F-10001}}
for _,pair in ipairs(pairs) do
    local c,t=pair[1],pair[2]
    local got=S.initialBowlsSpaghetti(c,t)
    local expected=O.initialBowls(O.workCounts(c,t))
    for id=1,6 do
        assert(B.compare(got[id],expected[id])==0,
               "Bòl inisyal pa kòrèk: "..c..":"..t..":"..id)
    end
    got[1].d[1]=999999
    local again=S.initialBowlsSpaghetti(c,t)
    assert(B.compare(again[1],expected[1])==0,"Bòl pataje referans")
end
for _,bad in ipairs({0.5,"2",{},false}) do
    assert(not pcall(S.initialBowlsSpaghetti,bad,F))
end
print("PASS Stage 18: 8 pè jou, 48 bòl inisyal, pa gen alias")
