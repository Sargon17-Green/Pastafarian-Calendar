local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local BigInt=require("bigint")
local Oracle=require("normative_oracle")
local Spaghetti=require("spaghetti")
local Legacy=require("legacy_permutation")

local F=Oracle.FOUNDATION_DAY
local cases={{F,F},{F+1,F-1},{F-5,F+9}}
local checked,shifted,missing=0,0,0
local function same(a,b)
    if a==nil or b==nil then return a==b end
    if #a~=6 or #b~=6 then return false end
    for k=1,6 do if a[k]~=b[k] then return false end end
    return true
end

-- Se yon tès ENTEGRASYON: gout yo sòti reyèlman nan PATCH 07, pa
-- nan yon lis valè fabrike ni nan Oracle.buildVisibleDrops.
for ci,pair in ipairs(cases) do
    local c,t=pair[1],pair[2]
    local visibleStore={}
    for i=1,3 do
        local drop,visibleContext=Spaghetti.visibleDropSpaghetti(c,t,i,visibleStore)
        assert(BigInt.compare(drop,1)>=0 and BigInt.compare(drop,Oracle.M)<=0,
               "Gout vizib ki sòti nan PATCH 07 pa nan domèn SAVE")
        assert(visibleContext.status=="PATCH_VISIBLE_COMPLETE")
        assert(visibleContext.completedGrinds==11 and #visibleContext.trace==11)
        local expectedOrder=Oracle.bowlOrderFromDrop(drop)
        local rankOneBased=Legacy.oldOneBasedRank(drop)
        assert(rankOneBased>=1 and rankOneBased<=720)
        local got,rankContext=Spaghetti.legacyPermutationProbe(drop)
        assert(rankContext.commitToken==2 and #rankContext.branchTrace==2)
        assert(rankContext.semanticState.rankOneBased==rankOneBased)
        if rankOneBased==720 then
            assert(got==nil and rankContext.status=="LEGACY_PERM_RANK_OUT_OF_RANGE",
                   "Rang 720 soti nan yon gout reyèl men pa ekspoze rejè legacy")
            missing=missing+1
        else
            assert(same(got,Legacy.oldPermutationUnrank0(rankOneBased)),
                   "Ou te chanje aksè historical unrank0 nan gout vizib "..ci..":"..i)
            assert(not same(got,expectedOrder),
                   "PATCH 08 te antre twò bonè nan chemen gout vizib la")
            shifted=shifted+1
        end
        visibleStore[i]=BigInt.from(drop)
        checked=checked+1
    end
end
assert(checked==9 and checked==shifted+missing)
print("PASS entegrasyon Stage 16: "..checked.." gout reyèl PATCH 07, "..
      shifted.." rang deplase, "..missing.." rang 720 rejte")
