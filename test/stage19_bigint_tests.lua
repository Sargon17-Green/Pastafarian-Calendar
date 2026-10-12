local root=arg[1] or "."
package.path=root.."/src/?.lua;"..root.."/test/?.lua;"..package.path
local B=require("bigint")
local O=require("normative_oracle")
local S=require("spaghetti")
local stones={w=B.from("1"..string.rep("9",75)),b=B.from("3"..string.rep("0",70)),
  s=B.from("7"..string.rep("4",60)),m=B.from(17),r=B.from(19)}
local old={}
for j=1,6 do old[j]=B.add(B.mul(B.from("1"..string.rep("0",84)),j),j*3) end
local samples={"0","1","120","121","240","241","719","720","721","-1","-720",
 "170141183460469231731687303715884105727",
 "-170141183460469231731687303715884105728",
 "1"..string.rep("0",255),"-"..string.rep("9",280)}
local seed=1919
for i=1,125 do
    local chars={tostring(seed%9+1)}
    for j=1,95+i do
        seed=(seed*48271)%2147483647
        chars[#chars+1]=tostring(seed%10)
    end
    samples[#samples+1]=(i%4==0 and "-" or "")..table.concat(chars)
end
local names={"w","b","s"}
local factors={3,5,7}
for _,str in ipairs(samples) do
    local drop=B.from(str)
    local got,ctx=S.pourPatchProbe(drop,46,old,stones)
    local order=O.bowlOrderFromDrop(drop)
    for p=1,3 do
        local expected=O.SAVE(drop*drop+stones[names[p]]*old[order[p]]
            + B.from(factors[p]*46))
        assert(B.compare(got[p],expected)==0,"Gwo BigInt echwe: "..str..":"..p)
    end
    assert(ctx.semanticState.dropDecimal==tostring(drop))
    local shifted=S.fixedBowlPoursSpaghetti(B.add(drop,720),46,old,stones)
    -- Same permutation, but pours are NOT periodic because drop^2 changes.
    local orderAgain=O.bowlOrderFromDrop(B.add(drop,720))
    assert(table.concat(orderAgain,",")==table.concat(order,","))
    for p=1,3 do
        local plus=B.add(drop,720)
        local expected=O.SAVE(plus*plus+stones[names[p]]*old[order[p]]+B.from(factors[p]*46))
        assert(B.compare(shifted[p],expected)==0)
    end
end
assert(#samples==140)
print("PASS Stage 19 BigInt: 140 antre, >256-bit, siy negatif, +720 lòd estab")
